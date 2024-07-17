(in-package :teatree)

;;; --- Generic ---

(defun expired? (created-at &key (hours 24))
  (> (timestamp-difference (now) (parse-timestring created-at))
     (* 3600 hours)))

(defun make-unique-filename (filename area id)
  (let ((ext (pathname-type (pathname filename)))
        (timestamp (timestamp-to-unix (now))))
    (sprintf "public/userdata/~a.~a.~a.~a" area id timestamp ext)))

(defun save-file (tmp-path dest-path)
  (ensure-directories-exist (relative-path dest-path))
  (copy-file tmp-path (relative-path dest-path)))

;;; --- Link ---

(defmodel link
  id
  profile-id
  title
  href
  created-at
  updated-at)

(defun new-link (profile-id title href)
  (make-link nil profile-id title href nil nil))

(defun find-link (&key id)
  (let ((res (retrieve-one *find-link-by-id* id)))
    (when res
      (apply #'make-link res))))

(defun find-all-links (&key profile-id username)
  (let ((res (cond (profile-id
                     (retrieve-all *find-all-links-by-profile-id* profile-id))
                   (username
                     (retrieve-all *find-all-links-by-username* username)))))
    (when res
      (mapcar (lambda (x)
                (apply #'make-link x))
              res))))

(defmethod valid? ((m link))
  (combine (valid-url? (link-href m))
           (not-empty? (link-title m))))

;;; --- Profile ---

(defmodel profile
  id
  user-id
  username
  title
  colour
  bg-colour
  image-url
  image-alt
  is-live
  css
  created-at
  updated-at)

(defun new-profile (user-id username)
  (make-profile nil user-id username nil nil nil nil nil nil nil nil nil))

(defun find-profile (&key id user-id username)
  (let ((res
          (cond (id (retrieve-one *find-profile-by-id* id))
                (user-id (retrieve-one *find-profile-by-user-id* user-id))
                (username (retrieve-one *find-profile-by-username* username)))))
    (when res
      (apply #'make-profile res))))

(defun existing-username? (username)
  (retrieve-single *existing-username* username))

(defmethod modify-live! ((m profile))
  (setf (profile-is-live m) 1)
  (modify! m))

(defmethod modify-image! ((m profile) temp-path)
  (save-file temp-path (profile-image-url m))
  (modify! m))

(defmethod is-live? ((m profile))
  (and (profile-is-live m)
       (= 1 (profile-is-live m))))

(defmethod valid? ((m profile))
  (combine (valid-username? (profile-username m))
           (or (empty? (profile-colour m))
               (valid-colour? (profile-colour m)))
           (or (empty? (profile-bg-colour m))
               (valid-colour? (profile-bg-colour m)))))

;;; --- User ---

(defmodel user
  id
  name
  email
  password
  created-at
  updated-at)

(defun new-user (name email password)
  (make-user nil name email password nil nil))

(defun find-user (&key id email username)
  (let ((res (cond (id (retrieve-one *find-user-by-id* id))
                   (email (retrieve-one *find-user-by-email* email))
                   (username (retrieve-one *find-user-by-username* username)))))
    (when res
      (apply #'make-user res))))

(defun find-auth-user (&key id email)
  (let ((res (cond (id (retrieve-one *find-auth-user-by-id* id))
                   (email (retrieve-one *find-auth-user-by-email* email)))))
    (when res
      (apply #'make-user res))))

(defun existing-email? (email)
  (retrieve-single *existing-email* email))

(defun existing-email-not-mine? (email my-id)
  (retrieve-single *existing-email-not-mine* email my-id))

(defmethod modify-password! ((m user) password)
  (setf (user-password m) (hash password))
  (modify! m))

(defmethod should-log-in? ((m user) password)
  (check-password? password (user-password m)))

(defmethod valid? ((m user))
  (combine (valid-email? (user-email m))
           (and (not-empty? (user-name m)))))

;;; --- Integration ---

(defmodel integration
  id
  profile-id
  mailchimp-subscribe-url
  created-at
  updated-at)

(defun new-integration (profile-id)
  (make-integration nil profile-id nil nil nil))

(defun find-integration (&key id username profile-id)
  (let ((res (cond (id
                     (retrieve-one *find-integration-by-id* id))
                   (username
                     (retrieve-one *find-integration-by-username* username))
                   (profile-id
                     (retrieve-one *find-integration-by-profile-id* profile-id)))))
    (when res
      (apply #'make-integration res))))

(defun get-subscribe-url (api-key)
  (let* ((region (cadr (split-string api-key :separator "-")))
         (lists-url (sprintf "https://~a.api.mailchimp.com/3.0/lists" region)))
    (flet ((fetch-subscribe-lists ()
             (parse
               (sb-ext:octets-to-string
                 (http-request lists-url
                               :additional-headers `(("Authorization" . ,(sprintf "Bearer ~a" api-key)))))
               :as :hash-table))
           (extract-url (res)
             (gethash "subscribe_url_long" (car (gethash "lists" res))))
           (splice-url (url)
             (let ((parts (split-string url :separator "?")))
               (sprintf "~a/post?~a" (car parts) (cadr parts)))))
      (splice-url (extract-url (fetch-subscribe-lists))))))

;;; --- Password reset request ---

(defmodel pw-reset-request
  id
  uuid
  user-id
  created-at
  updated-at)

(defun new-pw-reset-request (uuid user-id)
  (make-pw-reset-request nil uuid user-id nil nil))

(defun find-pw-reset-request (&key uuid)
  (let ((res (retrieve-one *find-pw-reset-request-by-uuid* uuid)))
    (when res
      (apply #'make-pw-reset-request res))))

(defmethod forgot-password-link ((m pw-reset-request))
  (sprintf "~a/forgot-password/~a"
           (getf *config* :hostname)
           (pw-reset-request-uuid m)))

(defmethod send-forgot-pw-email ((m pw-reset-request) email)
  (let* ((link (forgot-password-link m))
         (host (getf *config* :smtp-host))
         (mailer (getf *config* :mailer))
         (subject "Teatree -- Forgot password")
         (content (sprintf "Click this link to reset your password <~a>" link))
         (auth `(,(getf *config* :smtp-username)
                 ,(getf *config* :smtp-password)))
         (port (getf *config* :smtp-port)))
    (send-email host
                mailer
                email
                subject
                content
                :authentication auth
                :port port
                :ssl :starttls)))
