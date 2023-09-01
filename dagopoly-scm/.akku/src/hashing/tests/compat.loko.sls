;; SPDX-License-Identifier: MIT

(library (srfi :78 lightweight-testing compat)
  (export check:write)
  (import (rnrs))

(define (check:write . x)
  (apply write x)
  (newline)))
