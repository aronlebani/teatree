(in-package :teatree)

; todo - don't show log out link when not logged in

(defstatic "/public/" "public/")

;;; --- Index ---

(defroute index ("/") ()
  (render "index.html"))

;;; --- Signup ---

(defroute signup/new ("/signup") ()
  (render "signup.new.html"))

(defroute signup/create
          ("/signup" :method :post)
          (&post email password name username)
  ; todo - currently after signing up, you have to log in again
  (with-validation (combine (not-empty? name)
                            (valid-email? email)
                            (valid-username? username)
                            (valid-password? password))
    (cond ((existing-email? email)
           (render-error 409 "The email address ~a is already registered." email))
          ((existing-username? username)
           (render-error 409 "The username ~a is already in use." username))
          (t
           (let* ((u-id* (create! (new-user name email (hash password))))
                  (p-id* (create! (new-profile u-id* username)))
                  (i-id* (create! (new-integration p-id*))))
             (create-session :auth-user u-id*
                             :auth-profile p-id*)
               (redirect "/admin"))))))

;;; --- Login ---

(defroute login/edit ("/login") ()
  (render "login.edit.html"))

(defroute login/update ("/login" :method :post) (&post email password)
  (let ((u (find-auth-user :email email)))
    (if (and u (should-log-in? u password))
        (let ((p (find-profile :user-id (user-id u))))
          (create-session :auth-user (user-id u)
                          :auth-profile (profile-id p))
          (redirect "/admin"))
        (render-error 401 "Incorrect username or password."))))

;;; --- Logout ---

(defroute logout/destroy ("/logout") ()
  (drop-session)
  (redirect "/login"))

;;; --- Forgot password ---

(defroute forgot-password/new ("/forgot-password/new") ()
  (render "forgot-password.new.html"))

(defroute forgot-password/create ("/forgot-password" :method :post) (&post email)
  (with-resources ((u (find-user :email email)))
    (let ((uuid (make-uuid)))
      (with-new ((prr* (new-pw-reset-request uuid (user-id u))))
        (create! prr*)
        (send-forgot-pw-email prr* email)
        (sprintf "An email to reset your password has been sent to ~a" email)))))

(defroute forgot-password/edit ("/forgot-password/:uuid") ()
  (with-resources ((prr (find-pw-reset-request :uuid uuid)))
    (if (expired? (pw-reset-request-created-at prr))
        (render-error 410 "This link has expired.")
        (render "forgot-password.edit.html"))))

(defroute forgot-password/update
          ("/forgot-password/:uuid" :method :post)
          (&post password)
  (with-validation (combine (valid-password? password))
    (with-resources ((prr (find-pw-reset-request :uuid uuid))
                     (u (find-auth-user :id (pw-reset-request-user-id prr))))
      (modify-password! u password)
      (redirect "/login"))))

;;; --- Change password ---

(defroute change-password/edit ("change-password") ()
  (render "change-password.edit.html"))

(defroute change-password/update
          ("/change-password" :method :post)
          (&post old-password new-password)
  (with-validation (combine (valid-password? new-password))
    (with-resources ((u (find-auth-user :id (session-u-id))))
      (if (should-log-in? u old-password)
          (progn
            (modify-password! u new-password)
            (drop-session)
            (redirect "/login"))
          (render-error 401 "Incorrect password.")))))

;;; --- Admin ---

(defroute admin/show ("/admin" :decorators (@auth)) ()
  (with-resources ((p (find-profile :id (session-p-id)))
                   (u (find-user :id (session-u-id)))
                   (i (find-integration :profile-id (session-p-id))))
    (render "admin.show.html"
            :profile p
            :links (find-all-links :profile-id (session-p-id))
            :user u
            :integration i)))

;;; --- Public profile ---

(defroute public-profile/show ("/:username") ()
  (defun show-profile? (p)
    (or (is-live? p)
        (and (session-p-id)
             (= (profile-id p) (session-p-id)))))

  (with-resources ((p (find-profile :username username))
                   (i (find-integration :username username)))
    (if (show-profile? p)
        (render "public-profile.show.html"
                :profile p
                :integration i
                :links (find-all-links :username username))
        (render-error 404 "Not found."))))

;;; --- Link ---

(defroute link/new ("/profile/:p-id/link/new" :decorators (@auth)) ()
  (with-resources ((p (find-profile :id p-id)))
    (with-permission (:auth-profile p-id (profile-id p))
      (render "link.new.html" :profile p))))

(defroute link/create
          ("/profile/:p-id/link" :method :post :decorators (@auth))
          (&post title href)
  (with-resources ((p (find-profile :id p-id)))
    (with-permission (:auth-profile (profile-id p))
      (with-new ((l* (new-link (session-p-id) title href)))
        (with-validation (valid? l*) 
          (create! l*)
          (redirect "/admin"))))))

(defroute link/edit
          ("/profile/:p-id/link/:id/edit" :decorators (@auth)) ()
  (with-resources ((l (find-link :id id))
                   (p (find-profile :id p-id)))
    (with-permission (:auth-profile p-id (link-profile-id l))
      (render "link.edit.html" :link l :profile p))))

(defroute link/update
          ("/profile/:p-id/link/:id" :method :post :decorators (@auth))
          (&post title href)
  (with-resources ((l (find-link :id id)))
    (with-permission (:auth-profile p-id (link-profile-id l))
      (setf (link-title l) title)
      (setf (link-href l) href)
      (with-validation (valid? l)
        (modify! l)
        (redirect "/admin")))))

(defroute link/destroy
          ("/profile/:p-id/link/:id/delete" :method :post :decorators (@auth))
          ()
  (with-resources ((l (find-link :id id)))
    (with-permission (:auth-profile p-id (link-profile-id l))
      (destroy! l)
      (redirect "/admin"))))

;;; --- Profile ---

(defroute profile/edit ("/profile/:id/edit" :decorators (@auth)) ()
  (with-resources ((p (find-profile :id id)))
    (with-permission (:auth-profile id (profile-id p))
      (render "profile.edit.html" :profile p))))

(defroute profile/update
          ("/profile/:id" :method :post :decorators (@auth))
          (&post colour bg-colour image image-alt css)
  (with-resources ((p (find-profile :id id)))
    (with-permission (:auth-profile id (profile-id p))
      (setf (profile-colour p) colour)
      (setf (profile-bg-colour p) bg-colour)
      (setf (profile-image-alt p) image-alt)
      (setf (profile-css p) css)
      (when image
        (setf (profile-image-url p)
              (make-unique-filename (image-name image)
                                    "profile"
                                    (profile-id p))))
      (with-validation (valid? p)
        (modify! p)
        (when image
          (modify-image! p (image-temp-path image)))
        (redirect "/admin")))))

(defroute profile/update/live
          ("/profile/:id/live" :method :post :decorators (@auth)) ()
  (with-resources ((p (find-profile :id id)))
    (with-permission (:auth-profile id (profile-id p))
      (modify-live! p)
      (redirect "/admin"))))

;;; --- User ---

(defroute user/edit ("/user/:id/edit" :decorators (@auth)) ()
  (with-resources ((u (find-user :id id)))
    (with-permission (:auth-user id (user-id u))
      (render "user.edit.html" :user u))))

(defroute user/update
          ("/user/:id" :method :post :decorators (@auth))
          (&post name email)
  (with-resources ((u (find-user :id id)))
    (with-permission (:auth-user id (user-id u))
      (setf (user-name u) name)
      (setf (user-email u) email)
      (with-validation (valid? u)
        (if (existing-email-not-mine? email (session-u-id))
            (render-error 409 "The email ~a is already in use." email)
            (progn
              (modify! u)
              (redirect "/admin")))))))

;;; --- Integration ---

;;; --- Mailchimp ---

(defroute mailchimp/edit
          ("/profile/:p-id/integration/:id/mailchimp/edit" :decorators (@auth))
          ()
  (with-resources ((p (find-profile :id p-id))
                   (i (find-integration :id id)))
    (with-permission (:auth-profile p-id (integration-profile-id i))
      (render "integration/mailchimp.edit.html"
              :profile p
              :integration i))))

(defroute mailchimp/update
          ("/profile/:p-id/integration/:id/mailchimp"
           :method :post :decorators (@auth))
          (&post mailchimp-api-key)
  (with-resources ((i (find-integration :profile-id p-id)))
    (with-permission (:auth-profile p-id (integration-profile-id i))
      ; todo - need to make this more granular as the catch-all could
      ; obscure genuine bugs
      (handler-case (progn
                      (setf (integration-mailchimp-subscribe-url i)
                            (get-subscribe-url mailchimp-api-key))
                      (modify! i)
                      (redirect "/admin"))
        (error () (render-error 400 "Could not parse API key."))))))
