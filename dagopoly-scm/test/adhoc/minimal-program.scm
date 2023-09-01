;; Reminder to get env correctly:
;; (setq scheme-program-name "../../chezscheme.sh")
(import (micro dagopoly) (micro fs) (micro stream))
(activate-defaults)

(define-block count-to-n (n) v0.0
  (define (iter i)
    (if (>= i n)
	'()
	(lambda ()
	  (cons i (iter (+ i 1))))))
  (iter 0))

; or (define-block square (xs) v0.0
(define-block (square xs) v0.0
  (let loop ((xs (block-get xs)))
    (cond
     ((null? xs) '())
     ((procedure? xs) (xs))
     ((pair? xs)
      (let ((x (car xs)))
	(lambda ()
	  (cons (* x x) (loop (cdr xs))))))
     (else (raise `(unknown-stream-construction xs))))))

(block-sig (count-to-n 10))
(s->list (block-get (count-to-n 10)))

(block-sig (square (count-to-n 10)))

(block-sig (square (count-to-n 10)))

(block-sig (cache-block (square (count-to-n 10))))

(display "presuming that storage/derived has been deleted, about to recompute a result:\n")
;; prints "recomputing ..."
(display (format "  ~a\n"
		 (s->list (block-get (cache-block (square (count-to-n 10)))))))

(display "now we won't need to compute the same result\n")
;; does not print "recomputing ..."
(display (format "  ~a\n"
		 (s->list (block-get (cache-block (square (count-to-n 10)))))))
