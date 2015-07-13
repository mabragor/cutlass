
(in-package #:cutlass)

(enable-read-macro-tokens)

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
