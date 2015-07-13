;;;; cutlass.lisp

(in-package #:cutlass)

(cl-interpol:enable-interpol-syntax)

(defparameter *connection* nil)

(defmacro with-connection (&body body)
  `(let ((*connection* (connect :mysql :database-name "cutlass"
				:username "cutlass" :password "caramba!")))
     (unwind-protect (progn ,@body)
       (disconnect *connection*))))

(defun foo ()
  (with-connection
      (let ((res nil))
	(let* ((query (prepare *connection* "select User,Password from user"))
	       (result (execute query)))
	  (iter (for row next (let ((it (fetch result)))
				(or it (terminate))))
		(push row res)))
	res)))

(defparameter *rolfsen-total-numbers* '((3 . 1) (4 . 1) (5 . 2) (6 . 3) (7 . 7) (8 . 21) (9 . 49) (10 . 165)))
(defparameter *workdir* "/home/popolit/quicklisp/local-projects/cutlass/")

(defun gen-rolfsen-names-infile ()
  (with-open-file (stream #?"$(*workdir*)rolfsen-names-infile.txt"
			  :direction :output :if-exists :supersede)
    (let ((knot-id 0))
      (iter (for num-intersections from 3 to 10)
	    (iter (for num from 1 to (cdr (assoc num-intersections *rolfsen-total-numbers*)))
		  (format stream #?"~a\trolfsen:~a_~a\n" (incf knot-id) num-intersections num)))))
  :success!)

(defmacro with-html (&body body)
  `(with-html-output-to-string (*standard-output* nil :prologue t)
     ,@body))

(defun normalize-query (query)
  (string-trim '(#\space #\tab #\newline #\return) query))

(defun simple-name-query (query)
  (with-connection
      (let* ((sql (prepare *connection* "select knot_id from knot_names where name = ?"))
	     (result (execute sql query)))
	(iter (for row next (let ((it (fetch result)))
			      (or it (terminate))))
	      (collect row)))))

(defun raw-polynomial-query-p (query)
  (handler-case (cutlass-parse 'raw-polynomial query)
    (esrap-liquid::simple-esrap-error () nil)
    (:no-error (&rest args)
      (declare (ignore args))
      t)))

(defun raw-polynomial-query (query)
  (list :text-list
	(with-connection
	    (let* ((sql (prepare *connection* "select knot_id from 1_homflies where poly = ?"))
		   (result (execute sql query)))
	      (iter (for row next (let ((it (fetch result)))
				    (or it (terminate))))
		    (collect row))))))

(define-condition query-handling-error (error simple-condition)
  ())

(defmacro wont-handle ()
  `(error 'query-handling-error))

(defmacro query-handling-or (&rest clauses)
  ...)

(defun handle-query (query)
      
  (cond ((string= "ping" (string-downcase query))
	 (list :text "pong"))
	((string= "pong" (string-downcase query))
	 (list :unknown-tag :something))
	((raw-polynomial-query-p query) (raw-polynomial-query query))
	(t (let ((res (simple-name-query query)))
	     (if res
		 (list :text-list res)
		 nil)))))

(define-easy-handler (easy-demo :uri "/cutlass.ru/home.html"
				:default-request-type :get)
    ()
  (let (post-parameter-p query-result)
    (when (post-parameter "query")
      (setf query-result (handle-query (normalize-query (post-parameter "query"))))
      (setq post-parameter-p t))
    (no-cache)
    (with-html
      (:html
       (:head (:title "This is Cutlass"))
       (:body
	(:form :method :post :enctype "multipart/form-data"
	       (:p "What can I do for you?<br> "
		   (:textarea :id "query" :name "query" :rows "5" :cols "80"))
	       (:p (:input :type :submit :value "=)")))
	(when post-parameter-p
	  (htm :hr)
	  (if (not query-result)
	      (htm (:p "I'm sorry, but I don't know what you mean."))
	      (destructuring-bind (type result) query-result
		(cond ((eq :text type) (htm (:p (str result))))
		      ((eq :text-list type) (dolist (elt result)
					      (htm (:p (str elt)))))
		      (t (error "Unknown type of query result")))))))))))
