;;;; cutlass.asd

(asdf:defsystem #:cutlass
  :description "convenient knot database"
  :author "Alexandr Popolitov <popolit@gmail.com>"
  :license "MIT"
  :serial t
  :depends-on (#:hunchentoot #:dbd-mysql #:cl-dbi #:cl-mysql
			     #:iterate #:cl-interpol #:cl-who
			     #:esrap-liquid #:defmacro-enhance #:cg-common-ground
			     #:clesh #:named-readtables)
  :components ((:file "package")
	       (:file "parsing-macro")
	       (:file "parsing")
               (:file "cutlass")))

