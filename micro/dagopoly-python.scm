(define (cmd-python method arg)
  (let ((relf-ipc (get-config-required 'relfPythonipc (current-io))))
    (format "~a ~a ~a ~a" "python" relf-ipc method arg)))

(define (start-python method arg)
  (let ((cmd (cmd-python method arg)))
    (open-process-ports
     cmd
     (buffer-mode line)
     (make-transcoder (utf-8-codec)))))

(define (run-python-sig arg)
  (let-values (((stdin stdout stderr pid) (start-python "sig" arg)))
    (close-input-port stderr)
    (close-output-port stdin)
    (let ((l (json-read stdout)))
      (close-input-port stdout)
      l)))

(define (run-python-get arg)
  (define (iter stdout)
    (let ((l (read-line stdout)))
      (cond
       ((eof-object? l)
        (close-input-port stdout)
        '())
       (else
        (cons l (iter stdout))))))
  (lambda ()
    (let-values (((stdin stdout stderr pid) (start-python "get" arg)))
      ;;(display (format "spawned ~a\n" pid))
      (close-input-port stderr)
      (close-output-port stdin)
      (iter stdout))))

(define (block-python sym)
  (make-block
   (lambda (m)
     (case m
       ((sig)
        `(block-python ,(run-python-sig sym)))
       ((get)
        (lambda ()
	  (run-python-get sym)))))))
