(define (list->s a)
  (cond
   ((null? a) '())
   (else
    (lambda ()
      (cons (car a)
            (list->s (cdr a)))))))
(define (s->list s)
  (cond
   ((procedure? s) (s->list (s)))
   ((null? s) '())
   ((pair? s)
    (cons (car s) (s->list (cdr s))))
   (else
    (raise `(unknown-stream-construction: ,s)))))
