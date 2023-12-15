(in-package :teatree)

(defvar *config* nil)

(with-open-file (file (relative-path ".config"))
  (with-standard-io-syntax
    (setf *config* (read file))))

(defvar *app*
  (make-app :port (getf *config* :port)))

(defvar *db*
  (make-db (getf *config* :db-url)))

(defun main ()
  (if (getf *config* :debug)
      (setf *show-lisp-errors-p* t))
  (register-templates (relative-path "src/views/"))
  (start *app*))

