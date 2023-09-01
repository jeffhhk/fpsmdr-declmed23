(define (overwrite-file absf)
  (when (file-exists? absf)
    (delete-file absf)))

(define (read-text-file absf)
  (define (iter p)
    (let ((l #f))
      (lambda ()
        (unless l
          (set! l (cons
		   (read p)       ; replayable stream read
		   (iter p))))
        (if (eof-object? (car l))
            (begin
              (close-input-port p)
              '())
            l))))
  (let ((p (open-input-file absf)))
    (iter p)))

(define (write-text-file absf)
  (lambda (s)
    (let* ((absfTmp (string-append absf ".tmp"))
           (_ (overwrite-file absfTmp))
           (p (open-output-file absfTmp)))
      (define (iter p s)
        (cond
         ((procedure? s)
          (iter p (s)))
         ((null? s)
          (close-output-port p)
          (rename-file absfTmp absf))  ; write file atomically for future existence checks
         ((pair? s)
          (let ((l (car s)))
            (write l p)
            (newline p)
            (iter p (cdr s))))
         (else
          (raise `(unexpected-stream-item ,s)))))
      (iter p s))))

(define (get-config-required k alist)
  (let ((kv (assoc k alist)))
    (if kv
        (cdr kv)
        (raise (format "get-config-required: cannot find key ~a" k)))))

(define (get-config-default k alist v-default)
  (let ((kv (assoc k alist)))
    (if kv
        (cdr kv)
        v-default)))

(define (make-text-file-io opts)
  (let ((absdStore (get-config-required 'absdStore opts))
        (testing? (get-config-default 'testing? opts #f)))
    (lambda (m)
      (case m
        ((exists)
         (lambda (relf)
           (let ((absf (path-combine absdStore relf)))
             (file-exists? absf))))
        ((read)
         (lambda (relf)
           (let ((absf (path-combine absdStore relf)))
             (read-text-file absf))))
        ((write)
         (lambda (relf)
           (let* ((absf (path-combine absdStore relf))
                  (absd (path-parent absf)))
             (lambda (s)
               (mkdirp absd)
               (when testing?
                 (overwrite-file absf))
               ((write-text-file absf) s)))))
        (else (raise (format "make-text-file-io: unknown method: ~a" m)))
        ))))

(define current-io (make-parameter #f))

(define (activate-defaults)
  (let ((adirDagopoly (get-environment-variable "adirProj")))
    (unless adirDagopoly
      (error 'activate-defaults "please run from provided chezscheme.sh script"))
    (current-io
     (make-text-file-io
      `((absdStore . ,(path-combine adirDagopoly "storage"))
        (testing? . #t))))))

(define (sig->relf sig)
  (digest-string (format "~a" sig)))

(define (make-block b)
  `(block ,b))

(define (block? b)
  (and
   (pair? b)
   (equal? (car b) 'block)))

(define (block-body b)
  (cadr b))

(define (block-sig b)
  (if (block? b)
      ((block-body b) 'sig)
      b))

(define (block-get b)
  ((block-body b) 'get))

(define (cache-block b)
  (make-block
   (lambda (m)
     (case m
       ((sig)
        (block-sig b))
       ((get)
        (let* ((io (current-io))
               (sig (block-sig b))
               (relf (path-combine "derived" (sig->relf sig))))
          (if ((io 'exists) relf)
              ((io 'read) relf)
              (begin
                (display (format "recomputing ~a\n" sig))
                (((io 'write) relf) (block-get b))
                ((io 'read) relf)))))
       (else (raise (format "cache-block: unknown method: ~a" m)))))))

;;; Exogenous data, probably from a third-party data.  Stored under
;;; a special directory "exogenous".
(define (block-exogenous relf)
  (make-block
   (lambda (m)
     (case m
       ((sig)
        `(block-exogenous ,relf))
       ((get)
        (let ((io (current-io)))
          ((io 'read) (path-combine "exogenous" relf))))))))

(define-syntax define-block
  (syntax-rules ()
    ((_ (id . args) ver . body)
     (define (id . args)
       (make-block
        (lambda (m)
          (case m
            ((sig)
             `(,(quote id) ,(quote ver)
               ,(map block-sig (list . args))))
            ((get) (let () . body)
     ))))))
    ((_ id args ver . body)
     (define (id . args)
       (make-block
        (lambda (m)
          (case m
            ((sig)
             `(,(quote id) ,(quote ver)
               ,(map block-sig (list . args))))
            ((get) (let () . body)
             ))))))
     ))

;; as shown in the paper
(define-syntax define-block-simple
  (syntax-rules ()
    ((_ (id . args) ver . body)
     (define (id . args)
       (make-block
        (lambda (m)
          (case m
            ((sig)
             `(,(quote id) ,(quote ver)
               ,(map block-sig (list . args))))
            ((get) (let () . body)
             ))))))))
