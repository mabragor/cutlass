
(in-package #:cutlass)

(in-readtable :cutlass-parsing-syntax)

;; (enable-read-macro-tokens)

(define-cutlass-rule cipher ()
  (character-ranges (#\0 #\9)))

(define-cutlass-rule integer ()
  (list (? (|| #\- #\+)) (postimes cipher)))

(define-cutlass-rule raw-monomial ()
  c!-1-integer #\, c!-2-integer #\, c!-3-integer
  (list c!-1 c!-2 c!-3))

(define-cutlass-rule raw-polynomial ()
  (let ((first raw-monomial)
	(rest (times (progn #\; raw-monomial))))
    (cons first rest)))


(define-cutlass-rule whitespace ()
  (postimes (|| #\space #\tab #\newline #\return)))

(define-cutlass-rule mathematica-expr ()
  (|| compound-mathematica-expr
      atomic-mathematica-expr))

(define-cutlass-rule q-number ()
  (|| "qnum" "q" "QQ") #\[ c!-1-mathematica-expr #\]
  (list 'qnum c!-1))

(define-cutlass-rule atomic-mathematica-expr ()
  (|| q-number
      (progn (|| #\a #\A) 'a)
      (progn (|| #\q #\Q) 'q)
      (progn (|| #\z #\Z) 'z)
      (progn (|| #\n #\N) 'n)
      (parse-integer (text integer))))

(defmacro!! define-compound-mathematica-expr (name delim head)
    ()
  `(define-cutlass-rule ,name ()
     c!-1-mathematica-expr
     (? whitespace) ,delim
     (? whitespace) c!-2-mathematica-expr
     (list ,head c!-1 c!-2)))
  
;; (define-cutlass-rule times-expr ()
;;   (let ((pre-lhs (text (postimes (! #\*)))))
;;     #\*
;;     (? whitespace)
;;     c!-rhs-mathematica-expr
;;     (list 'times lhs c!-rhs)))


(define-compound-mathematica-expr times-expr #\* times)
(define-compound-mathematica-expr power-expr #\^ power)
(define-compound-mathematica-expr minus-expr #\- minus)
(define-compound-mathematica-expr plus-expr #\+ plus)
    

(define-cutlass-rule compound-mathematica-expr ()
  ;; can precedence even be encoded in the order of clauses ?
  (|| plus-expr
      minus-expr
      times-expr
      power-expr
      implicit-times-expr))

  
;; this matching is kind of complicated -- for now I'll implement a rather
;; simpler check, but not necessarily completely secure one

(define-cutlass-rule allowed-ns-char ()
  (|| (|| #\a #\A #\n #\N #\q #\Q #\z #\Z)
      (|| #\[ #\] #\( #\))
      (|| #\* #\- #\+ #\^)
      cipher))
  

(define-cutlass-rule lousy-mathematica-poly ()
  (postimes (|| whitespace
		allowed-ns-char)))
