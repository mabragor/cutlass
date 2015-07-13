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
(defparameter *workdir* "/home/hunchentoot/")

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
  (with-connection
      (let* ((sql (prepare *connection* "select knot_id from 1_homflies where poly = ?"))
	     (result (execute sql query)))
	(let ((res (iter (for row next (let ((it (fetch result)))
					 (or it (terminate))))
			 (collect row))))
	  (if (not res)
	      (list :text "No knots matched your polynomial, sorry.")
	      (list :text-list res))))))

(define-condition query-handling-error (error simple-condition)
  ())

(defmacro wont-handle ()
  `(error 'query-handling-error))

(defmacro! query-handling-or (&rest clauses)
  `(block ,g!-tag
     ,@(mapcar (lambda (clause)
		 `(handler-case ,clause
		    (query-handling-error () nil)
		    (:no-error (&rest things)
		      (return-from ,g!-tag (values-list things)))))
	       clauses)))

(defmacro define-query-handler (name cond &body body)
  `(defun ,name ()
     (declare (special *query*))
     (if ,cond
	 (progn ,@body)
	 (wont-handle))))

(define-query-handler ping-easter-egg (string= "ping" (string-downcase *query*))
  (list :text "pong"))

(define-query-handler pong-easter-egg (string= "pong" (string-downcase *query*))
  (list :unknown-tag :something))

(define-query-handler raw-polynomial (raw-polynomial-query-p *query*)
  (raw-polynomial-query *query*))

(define-query-handler simple-name-query-handler t
  (let ((res (simple-name-query *query*)))
    (if res
	(list :text-list res)
	(wont-handle))))

(defun looks-kinda-like-mathematica-polynomial-p (thing)
  (handler-case (cutlass-parse 'lousy-mathematica-poly thing)
    (error () nil)
    (:no-error (&rest things)
      (declare (ignore things))
      t)))

(defmacro mathematica-bulk-send (pattern o!-lst)
  (let ((g!-lst (gensym "LST")))
    `(let ((,g!-lst ,o!-lst))
       (with-open-file (stream #?"$(*workdir*)lisp-out.txt"
			       :direction :output :if-exists :supersede)
	 (iter (for ,pattern in ,g!-lst)
	       ,@(if (atom pattern)
		     `((format stream ,#?"$((stringify-symbol pattern)) = ~a;~%" ,pattern))
		     (mapcar (lambda (x)
			       `(format stream ,#?"$((stringify-symbol x)) = ~a;~%" ,x))
			     pattern)))))))

(defun mathematica-bulk-run (script-name)
  (multiple-value-bind (out err errno)
      (script #?"math -script $(script-name) > $(*workdir*)lisp-in.txt")
    ;; (declare (ignore out))
    (if (not (zerop errno))
	(error err)
	out)))

(defun mathematica-bulk-receive ()
  (iter (for expr in-file #?"$(*workdir*)lisp-in.txt" using #'read-line)
	(collect expr)))

(defmacro mathematica-bulk-exec (pattern script lst)
  `(progn (mathematica-bulk-send ,pattern ,lst)
	  (mathematica-bulk-run ,script)
	  (mathematica-bulk-receive)))

(defun get-raw-poly-representation (thing)
  (mathematica-bulk-send expr (list (cl-ppcre:regex-replace-all #?"\n|\t|\r" thing " ")))
  "1,2,3")

(define-query-handler mathematica-polynomial
    (looks-kinda-like-mathematica-polynomial-p *query*)
  (let ((raw (handler-case (get-raw-poly-representation *query*)
	       (error () (wont-handle)))))
    (list :text "Should've created lisp-out.txt")))
;; (raw-polynomial-query raw)))

(defun handle-query (query)
  (let ((*query* query))
    (declare (special *query*))
    (query-handling-or (ping-easter-egg)
		       (pong-easter-egg)
		       (mathematica-polynomial)
		       (raw-polynomial)
		       (simple-name-query-handler))))


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
