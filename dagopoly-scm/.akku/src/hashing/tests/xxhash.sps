#!/usr/bin/env scheme-script
;; -*- mode: scheme; coding: utf-8 -*- !#
;; Copyright © 2018 Göran Weinholt <goran@weinholt.se>

;; Permission is hereby granted, free of charge, to any person obtaining a
;; copy of this software and associated documentation files (the "Software"),
;; to deal in the Software without restriction, including without limitation
;; the rights to use, copy, modify, merge, publish, distribute, sublicense,
;; and/or sell copies of the Software, and to permit persons to whom the
;; Software is furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
;; THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;; DEALINGS IN THE SOFTWARE.
#!r6rs

(import (rnrs (6))
        (srfi :64 testing)
        (hashing xxhash))

(test-begin "xxh32")
(test-equal "02cc5d05" (xxh32->string (xxh32 #vu8())))

(test-equal "10659a4d" (xxh32->string (xxh32 (string->utf8 "A"))))

(test-equal "aa960ca6" (xxh32->string (xxh32 (string->utf8 "ABCD"))))
(test-equal "68729e13" (xxh32->string (xxh32 (string->utf8 "ABCD01234"))))
(test-equal "c2c45b69" (xxh32->string (xxh32 (string->utf8 "0123456789abcdef"))))
(test-equal "eb888d30" (xxh32->string
                        (xxh32 (string->utf8 "0123456789abcdef0123456789abcdef"))))
(test-equal "c6e5ca9a" (xxh32->string
                        (xxh32 (make-bytevector (* 1024 1024) #x55))))
(test-end)




;; (test-begin "xxh64")
;; (test-equal "ef46db3751d8e999" (xxh64->string (xxh64 #vu8())))
;; (test-end)

(exit (if (zero? (test-runner-fail-count (test-runner-get))) 0 1))
