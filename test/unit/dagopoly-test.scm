(import (micro dagopoly))
(import (micro fs))
(import (micro stream))
(import (srfi :78))

(define adirTest (make-parameter #f))

(define (test1-setup)
  (adirTest "/tmp/scmpipe")
  (mkdirp (adirTest)))

(define (test1-teardown)
  'TODO)

(define (assert p)
  (when (not p)
    (raise (format "assertion failure: ~a" p))))

(define (test-roundtrip-text-file absf s)
  (overwrite-file absf)
  ((write-text-file absf) s)
  (let ((l1 (s->list s))
	(l2 (s->list (read-text-file absf))))
    (assert (equal? l1 l2))))

(test1-setup)

(check (overwrite-file "/tmp/scmpipe/w1") => #t)

(define string123 '("1" "2" "3"))

(check ((write-text-file "/tmp/scmpipe/w1") string123)
       => (void))

(check (s->list (read-text-file "/tmp/scmpipe/w1"))
       => string123)

(check (test-roundtrip-text-file "/tmp/scmpipe/w1" '("1" "2" "3"))
       => (void))

(check (test-roundtrip-text-file "/tmp/scmpipe/w1" '(1 2 3))
       => (void))
(check (test-roundtrip-text-file "/tmp/scmpipe/w1" '(a b c))
       => (void))
(check (test-roundtrip-text-file "/tmp/scmpipe/w1" '((a) (b) (c)))
       => (void))

(check (path-combine "/foo/bar" "baz")
       => "/foo/bar/baz")
(check (path-combine "/foo/bar/" "baz")
       => "/foo/bar/baz")
;; Error, as expected: (path-combine "/foo/bar/" "/baz")

(define (check-ex e? expr)
  (guard (ex ((e? ex) #t)
	     (else #f))
	 (expr)))

(check-ex string?
	  (lambda ()
	    (path-combine "/foo/bar/" "/baz")))


;; TODO: URI
(check (path-combine "file://foo/bar/" "baz")
       => "file://foo/bar/baz")
;; TODO: are path-* functions unusable for URIs when on windows?

;;(mkdirp "/tmp/scmpipe/dir1/1/2/3")

(define io-test-config
  '((absdStore . "/tmp/scmpipe")
    (testing? . #t)))

;; Other possible implementations of -io protocol:
;;   different formats: fasl, custom
;;   different stores: s3 persistence, etc.

(check (((make-text-file-io io-test-config) 'exists) "dir1")
       => #f)
;;((make-text-file-io io-test-config) 'error)
(check ((((make-text-file-io io-test-config) 'write) "w1") '(1 2 4))
       => (void))
(check (s->list (((make-text-file-io io-test-config) 'read) "w1"))
       => '(1 2 4))


#;(define-block (block1 i-from i-to)
  (let loop ((i i-from))
    (lambda ()
      (if (<= i i-to)
	  (cons i (loop (+ i 1)))
	  '()))))

(define (block1-expanded i-from i-to)
  (make-block
   (lambda (m)
     (case m
       ((sig)
	`(block1 ,(block-sig i-from) ,(block-sig i-to)))
       ((get)
	(let loop ((i i-from))
	  (lambda ()
	    (if (<= i i-to)
		(cons i (loop (+ i 1)))
		'()))))))
   ))


(define-block block2 (i-from i-to) v1.10
  (let loop ((i i-from))
    (lambda ()
      (if (<= i i-to)
	  (cons i (loop (+ i 1)))
	  '()))))



(check (block-sig (block2 3 5))
       => '(block2 v1.10 (3 5)))
(check (s->list (block-get (block2 3 5)))
       => '(3 4 5))

(define-block block-reverse (b) v1
  (lambda ()
    (list->s (reverse (s->list (block-get b))))))

(check (car (block-reverse (block2 3 5)))
       => 'block)
(check (procedure? (cadr (block-reverse (block2 3 5))))
       => #t)
(check (block? (block-reverse (block2 3 5)))
       => #t)
(check (block-sig (block-reverse (block2 3 5)))
       => '(block-reverse v1 ((block2 v1.10 (3 5)))))
(check (s->list (block-get (block-reverse (block2 3 5))))
       => '(5 4 3))

;; mock a third-party/external data source
(check ((((make-text-file-io io-test-config) 'write) "external/w1") '(1 2 4))
       => (void))

;; read back the external data source
(check
 (parameterize ((current-io (make-text-file-io io-test-config)))
   (s->list (block-get (block-reverse (block-exogenous "w1")))))
 => '(4 2 1))

(check
 (parameterize ((current-io (make-text-file-io io-test-config)))
   (s->list (block-get (cache-block (block-reverse (block-exogenous "w1"))))))
 => '(4 2 1))

(test1-teardown)
(check-report)
