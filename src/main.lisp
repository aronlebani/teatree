(in-package :teatree)

(defvar *config* nil)

(with-open-file (file (relative-path ".config"))
  (with-standard-io-syntax
    (setf *config* (read file))))

(defvar *app*
  (make-app :port (getf *config* :port)))

(defvar *db*
  (make-db (getf *config* :db-url)))

(defvar *templates*
  (make-hash-table :test #'equal))

(register-templates (relative-path "src/views/"))

(defun dbg ()
  (setf *show-lisp-errors-p* t) 
  (start *app*)
  (format t "DEBUG: Hunchentoot server is started~&")
  (format t "DEBUG: Listening on localhost:~a~&" (getf *config* :port)))

(defun main ()
  (start *app*)
  (format t "Hunchentoot server is started~&")
  (format t "Listening on localhost:~a~&" (getf *config* :port))
  (handler-case (join-thread
                  (find-if (lambda (th)
                             (search "hunchentoot" (thread-name th)))
                           (all-threads)))
    ; Catch C-c
    (sb-sys:interactive-interrupt ()
      (progn
        (format *error-output* "Aborting~&")
        (stop *server*)
      (quit)))
    ; Something went wrong
    (error (c)
      (format t "An unknown error occured:~&~a~&" c))))
