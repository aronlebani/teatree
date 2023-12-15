(in-package :asdf)

(defsystem :teatree
  :author "Aron Lebani <aron@lebani.dev>"
  :maintainer "Aron Lebani <aron@lebani.dev>"
  :license "MIT"
  :homepage "https://github.com/aronlebani/teatree.git"
  :version "0.1"
  :description "A personal landing page for the web"
  :long-description #.(uiop:read-file-string
                        (uiop:subpathname *load-pathname* "README.md"))
  :build-operation program-op
  :build-pathname "app"
  :entry-point "teatree:main"
  :depends-on ("cl-ppcre"
               "cl-smtp"
               "djula"
               "drakma"
               "easy-routes"
               "hunchentoot"
               "hunchentoot-errors"
               "ironclad"
               "jonathan"
               "local-time"
               "sqlite"
               "uuid")
  :components ((:module "src"
                :components ((:file "package")
                             (:file "helpers")
                             (:file "models")
                             (:file "sql")
                             (:file "controllers")
                             (:file "main")))))
