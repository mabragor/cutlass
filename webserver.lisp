
(defpackage :webserver
  (:use :common-lisp :hunchentoot :cl-who))

(in-package #:webserver)
(setf *dispatch-table*
      (list #'dispatch-easy-handlers
	    #'default-dispatcher))

(setf *show-lisp-errors-p* t
      *show-lisp-backtraces-p* t)

(define-easy-handler (say-yo :uri "/yo") (name)
  (setf hunchentoot::*content-type* "text/plain")
  (format nil "Hey~@[ ~a~]!" name))

(define-easy-handler (easy-demo :uri "/lisp/hello"
				:default-request-type :get)
    ((state-variable :parameter-type 'string))
  (with-html-output-to-string (*standard-output* nil :prologue t)
    (:html
     (:head (:title "Hello, world!"))
     (:body
      (:h1 "Hello, world!")
      (:p "This is my Lisp web server, running on Hunchentoot,"
	  " as described in "
	  (:a :href
	      "http://newartisans.com/blog_files/hunchentoot.primer.php"
	      "this blog entry")
	  " on Common Lisp and Hunchentoot.")))))