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
  :build-pathname "teatree"
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
                             (:file "main")))
               (:module "src/views"
                :components ((:static-file "layout.html")
                             (:static-file "change-password.edit.html")
                             (:static-file "error.html")
                             (:static-file "forgot-password.edit.html")
                             (:static-file "forgot-password.new.html")
                             (:static-file "index.html")
                             (:static-file "link.edit.html")
                             (:static-file "link.index.html")
                             (:static-file "link.new.html")
                             (:static-file "link.show.html")
                             (:static-file "login.edit.html")
                             (:static-file "profile.edit.html")
                             (:static-file "profile.show.html")
                             (:static-file "public-profile.show.html")
                             (:static-file "signup.new.html")
                             (:static-file "user.edit.html")
                             (:static-file "user.show.html")
                             (:static-file "integration/index.show.html")
                             (:static-file "integration/mailchimp.edit.html")
                             (:static-file "admin.show.html")))))
