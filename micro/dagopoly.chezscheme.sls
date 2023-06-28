(library (micro dagopoly)
  (export overwrite-file read-text-file write-text-file
	  path-combine mkdirp
	  get-config-required get-config-default
	  make-text-file-io
	  current-io
	  sig->relf
	  make-block block? block-body block-sig block-get cache-block
	  block-external define-block
	  s->list list->s
	  )
  (import (scheme)
	  (arew json)
	  (hashing sha-1)
	  (micro stream)
	  )
  (define read-line get-line)
  (define (path-combine p1 p2)
    (let ((p1 (if (equal? "" (path-last p1)) (path-parent p1) p1)))
      (when (equal? "/" (path-first p2))
	(raise (format "path-combine: cannot be absolute: ~a" p2)))
      (string-append p1 (make-string 1 (directory-separator)) p2)))

  (define (mkdirp p)
    (define (mkdir-impl p) (mkdir p)) ; useful for tracing
    (cond
     ((equal? "" (path-last p)) (mkdirp (path-parent p)))  ;; trailing slash
     ((and (file-exists? p) (file-directory? p)) #t)       ;; already exists
     ((file-exists? p) (raise (format "mkdirp: file already exists: ~a" p)))
     ((file-exists? (path-parent p)) (mkdir-impl p))
     (else
      (mkdirp (path-parent p))
      (when (file-exists? (path-parent p)) (mkdir-impl p)))))

  (define (digest-string st)
    (sha-1->string (sha-1 (string->utf8 st))))

  (define (get-environment-variable st)
    (getenv st))

  (include "dagopoly.scm"))
