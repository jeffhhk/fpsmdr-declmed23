(library (micro dagopoly)
  (export overwrite-file read-text-file write-text-file
	  path-combine mkdirp
	  get-config-required get-config-default
	  make-text-file-io
	  current-io
	  sig->relf
	  make-block block? block-body block-sig block-get cache-block
	  block-exogenous define-block
	  activate-defaults
	  )
  (import (scheme)
	  (arew json)
	  (hashing sha-1)
	  (micro stream)
	  (micro fs)
	  )

  (define (digest-string st)
    (sha-1->string (sha-1 (string->utf8 st))))

  (define (get-environment-variable st)
    (getenv st))

  (include "dagopoly.scm"))
