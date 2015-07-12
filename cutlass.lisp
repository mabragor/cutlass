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