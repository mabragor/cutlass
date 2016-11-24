
(in-package #:cutlass)

(defreadtable :cutlass-parsing-syntax
    (:merge :standard)
  (:macro-char #\( #'cl-read-macro-tokens::read-list-new))

;; (in-readtable :cutlass-parsing-syntax)

;; (enable-read-macro-tokens)

(define-esrap-env cutlass)
