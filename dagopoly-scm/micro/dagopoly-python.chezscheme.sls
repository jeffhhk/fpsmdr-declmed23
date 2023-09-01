(library (micro dagopoly-python)
  (export 
   block-ipc
   )
  (import
   (scheme)
   (arew json)
   (hashing sha-1)
   (micro dagopoly)
   (micro stream)
   )
  (define (get-environment-variable st)
    (getenv st))
  (define read-line get-line)
  (include "dagopoly-python.scm")
  )
