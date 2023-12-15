(in-package :teatree)

;;; --- Application ---

(defclass acceptor (easy-routes-acceptor errors-acceptor) ()
  (:documentation
    "Hunchentoot acceptor that uses easy-routes and hunchentoot-errors."))

(defun make-app (&key port)
  "Create an instance of the server object."
  (make-instance 'acceptor :port port))

(defmacro defstatic (uri path)
  "Define a static dispatch handler to serve static files under path from uri."
  `(push (create-folder-dispatcher-and-handler ,uri (relative-path ,path))
         *dispatch-table*))

(defmacro render-error (error-code message &rest message-params)
  "Set the HTTP error code to error-code and render an error message. The
   message is passed as a control string to format, using message-params
   as the parameters."
  `(progn
     (setf (return-code*) ,error-code)
     (render "error.html"
             :code ,error-code
             :message (format nil ,message ,@message-params))))

(defun @auth (next)
  "A middleware function that checks for an existing session. If not, returns
   a 401 error."
  (if (and (session-value :auth-user) (session-value :auth-profile))
      (funcall next)  
      (progn
        (setf (return-code*) 401)
        (redirect "/login"))))

(defmacro with-permission ((session-key &rest identities) &body body)
  "Check if the identity ident matches the one stored in the session under the
   key session-key. If so, evaluate the body. If not, return a 403 error."
  `(let ((has-permission? (apply #'= (cons (session-value ,session-key)
                                           (ensure-integer ,@identities)))))
     (if has-permission?
         (progn
           ,@body)
         (progn
           (render-error 403 "Permission error")))))

(defmacro with-resources (letforms &body body)
  "A thin wrapper around let* which returns a 404 error if any of the let
   bindings evaluate to nil."
  `(let* ,letforms
     (if (some #'null
               (list ,@(mapcar #'car letforms)))
         (progn
           (render-error 404 "Not found"))
         (progn
           ,@body))))

(defmacro with-new (letforms &body body)
  "An even thinner wrapper around let*. Doesn't do anything. This is really
   just syntactic sugar to make the controllers look nicer."
  `(let* ,letforms
     ,@body))

(defmacro with-validation (errors &body body)
  "If the errors list is non-empty, return a 400 error. Otherwise, evaluate
   the body forms."
  `(if (> (length ,errors) 0)
       (progn
         (render-error 400 "Errors: ~{~a~^, ~}" ,errors))
       (progn
         ,@body)))

(defmacro create-session (&key auth-user auth-profile)
  "Start a new session using the keys auth-user and auth-profile."
  `(progn
     (start-session)
     (setf (session-value :auth-user) ,auth-user)
     (setf (session-value :auth-profile) ,auth-profile)))

(defmacro drop-session (&rest keys)
  "Deletes the entire session."
  `(progn
     (delete-session-value :auth-user)
     (delete-session-value :auth-profile)))

(defmacro session-u-id ()
  "A helper function to get the auth-user session value."
  `(session-value :auth-user))

(defmacro session-p-id ()
  "A helper function to get the auth-profile session value."
  `(session-value :auth-profile))

(defmacro image-temp-path (image)
  "Extract the temporary image path from a hunchentoot image request object."
  `(car ,image))

(defmacro image-name (image)
  "Extract the image name from a hunchentoot image request object."
  `(cadr ,image))

;;; --- Auth ---

(defun hash (password)
  "Hash a password using sha256 with a random salt."
  (let ((bytes (sb-ext:string-to-octets password)))
    (pbkdf2-hash-password-to-combined-string bytes
                                             :salt (make-random-salt)
                                             :digest :sha256
                                             :iterations 20000)))

(defun check-password? (password password-hash)
  "Check if hashed password is valid."
  (let ((bytes (sb-ext:string-to-octets password)))
    (pbkdf2-check-password bytes password-hash)))

(defun make-uuid ()
  "Create a v4 uuid."
  (princ-to-string (make-v4-uuid)))

;;; --- Database ---

(defun make-db (url)
  "Create and return a new database connection."
  (let ((conn (connect (relative-path url))))
    (execute-non-query conn "pragma busy_timeout = 3000;")
    conn))

(defmacro execute (sql &rest params)
  "Execute the sql string against the database connection with the parameters
   params and return nothing."
  `(execute-non-query *db* ,sql ,@params))

(defmacro retrieve-single (sql &rest params)
  "Execute the sql string against the database connection with the parameters
   params and return a single datum."
  `(execute-single *db* ,sql ,@params))

(defmacro retrieve-one (sql &rest params)
  "Execute the sql string against the database connection with the parameters
   params and return a single row as a list."
  `(car (execute-to-list *db* ,sql ,@params)))

(defmacro retrieve-all (sql &rest params)
  "Execute the sql string against the database connection with the parameters
   params and return multiple rows as a list of lists."
  `(execute-to-list *db* ,sql ,@params))

(defun prefix-symbol (prefix name)
  (read-from-string (format nil "~a-~a" prefix name)))

(defun kebab->snake (obj)
  (regex-replace-all "-" (format nil "~a" obj) "_"))

(defmacro defmodel (struct-name &rest slots)
  "defmodel struct-name {slot}*
   slot = slot-name [:type slot-type [:not-null]]

   Defines a struct struct-name with the given slots, a constructor make- which
   takes every slot as an argument, and a constructor new-, which takes only
   the not-null slots as arguments. Defines a function fields- which returns a
   list of the slot names."
  `(progn
     (defstruct (,struct-name
                  (:constructor ,(prefix-symbol "make" struct-name) ,slots))
       ,@slots)

     (defun ,(prefix-symbol struct-name "fields") (&key prefix obfuscate)
       (csv ',(mapcar #'kebab->snake slots)
            :prefix prefix
            :obfuscate obfuscate))

     (defmethod slot-fields ((m ,struct-name))
       ',(mapcar #'kebab->snake slots))

     (defmethod slot-names ((m ,struct-name))
       ',slots)

     (defmethod slot-placeholders ((m ,struct-name))
       ',(loop repeat (length slots) collecting #\?))

     (defmethod model? ((m ,struct-name))
       t)

     (defmethod create! ((m ,struct-name))
       (setf (slot-value m 'created-at) (current-time))
       (setf (slot-value m 'updated-at) (current-time))
       (let ((sql "insert into ~as (~{~a~^, ~}) values (~{~a~^, ~}) returning id;"))
         (retrieve-single (sprintf sql
                                   ,(kebab->snake struct-name)
                                   (slot-fields m)
                                   (slot-placeholders m))
                          ,@(mapcar (lambda (slot)
                                      `(slot-value m ',slot))
                                    slots))))

     (defmethod modify! ((m ,struct-name))
       (setf (slot-value m 'updated-at) (current-time))
       (let ((sql "update ~as set ~{~a = ?~^, ~} where id = ? returning id;"))
         (retrieve-single (sprintf sql
                                   ,(kebab->snake struct-name)
                                   (slot-fields m))
                          ,@(mapcar (lambda (slot)
                                      `(slot-value m ',slot))
                                    slots) 
                          (slot-value m 'id))))

     (defmethod destroy! ((m ,struct-name))
       (retrieve-single
         (sprintf "delete from ~as where id = ? returning id;" ',struct-name)
         (slot-value m 'id)))))

;;; --- Templates ---

(defvar *templates* (make-hash-table :test #'equal))

(defun push-template (template-path base-dir)
  (let ((key (enough-namestring template-path base-dir)))
    (setf (gethash key *templates*) (compile-template* key))))

(defun register-templates (base-dir)
  "Searches recursively for all html files in base-dir and registers them as
   templates."
  (setf (getf *default-template-arguments* :year) (current-year))
  (setf (getf *default-template-arguments* :hostname) (getf *config* :hostname))
  (add-template-directory base-dir)
  (collect-sub*directories base-dir
                           (constantly t)
                           (constantly t)
                           (lambda (dir)
                             (mapc (lambda (x)
                                     (push-template x base-dir))
                                   (remove-if-not #'html-file?
                                                  (directory-files dir))))))

(defmacro render (name &rest objects)
  "Render the template name with the given objects."
  `(render-template* (gethash ,name *templates*)
                     nil
                     ,@(loop for obj in objects and i from 0
                             collect (if (evenp i)
                                         obj
                                         `(struct->alist ,obj)))))

;;; --- Filesystem ---

(defun relative-path (path)
  "Get the path relative to the root directory of the project."
  (merge-pathnames path (system-source-directory :teatree)))

;;; --- HTTP ---

(defun bearer (token)
  "Create an HTTP bearer authentication string."
  (sprintf "Bearer ~a" token))

;;; --- Validation ---

(defmacro defvalidator (name message args &body body)
  "Define a validator function. Message is a control string that is passed to
   format with args."
  `(defun ,name (,@args)
     (if ,@body
         t
         (format nil ,message ,@args))))

(defun combine (&rest errors)
  (remove-if-not #'stringp errors))

(defvalidator valid-username? "Invalid username - ~a" (username)
  (scan "^[a-zA-Z_-]+[a-zA-Z0-9_-]+" username))

(defvalidator valid-password? "Invalid password" (password)
  (> (length password) 8))

(defvalidator valid-colour? "Invalid colour - ~a" (colour)
  (scan "^#{1}[a-fA-F0-9]{6}" colour))

(defvalidator valid-image? "Invalid image - ~a" (image)
  (scan ".+(.jpe?g|.png)$" image))

(defvalidator valid-email? "Invalid email - ~a" (email)
  (scan "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$" email))

(defvalidator valid-url? "Invalid URL - ~a" (url)
  (scan "((([A-Za-z]{3,9}:(?:\\/\\/)?)(?:[\\-;:&=\\+\\$,\\w]+@)?[A-Za-z0-9\\.\\-]+|(?:www\\.|[\\-;:&=\\+\\$,\\w]+@)[A-Za-z0-9\\.\\-]+)((?:\\/[\\+~%\\/\\.\\w\\-_]*)?\\??(?:[\\-\\+=&;%@\\.\\w_]*)#?(?:[\\.\\!\\/\\\\\\w]*))?)"
        url))

(defvalidator not-empty? "~a is required" (text)
  (> (length text) 0))

;;; --- Misc ---

(defmacro printf (&rest args)
  "Print a formatted string. This is a thin wrapper around format."
  `(format t ,@args))

(defmacro sprintf (&rest args)
  "Return a formatted string. This is a thin wrapper around format."
  `(format nil ,@args))

(defun current-year ()
  "Get the current year in the format YYYY."
  (timestamp-year (now)))

(defun current-time ()
  "Get the current time in the format YYYY-MM-DDTHH:MM:SS.mmmmmm+HH:MM."
  (format-timestring nil (now)))

(defun insert-after (lst index element)
  (push element (cdr (nthcdr index lst)))
  lst)

(defun struct->alist (struct)
  (if (listp struct)
      (mapcar #'struct->alist struct)
      (if (ignore-errors (model? struct))
          (loop for slot in (slot-names struct)
                collect (cons slot
                              (slot-value struct slot)))
          struct)))

(defun html-file? (file)
  (equal (pathname-type file) "html"))

(defun empty? (str)
  (= (length str) 0))

(defun csv (fields &key prefix obfuscate)
  (flet ((prefix-field (f)
           (if prefix
               (format nil "~a.~a" prefix f)
               f))
         (obfusc-field (f)
           (if (string= obfuscate f)
               (format nil "~a as ''" f)
               f)))
    (format nil "~{~a~^, ~}" (mapcar (lambda (x)
                                       (prefix-field (obfusc-field x)))
                                     fields))))

(defun ensure-integer (&rest maybe-ints)
  (mapcar (lambda (x)
            (if (integerp x)
                x
                (parse-integer x)))
          maybe-ints))
