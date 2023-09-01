#!/usr/bin/env scheme-script
;; -*- mode: scheme; coding: utf-8 -*- !#
;; Copyright © 2009, 2010, 2017, 2018 Göran Weinholt <goran@weinholt.se>

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
        (hashing crc))

;; Simple tests on the pre-defined CRCs:

(test-begin "crc-predefined")
(define-crc crc-32)
(test-equal 'success (crc-32-self-test))

(define-crc crc-16)
(test-equal 'success (crc-16-self-test))

(define-crc crc-16/ccitt)
(test-equal 'success (crc-16/ccitt-self-test))

(define-crc crc-32c)
(test-equal 'success (crc-32c-self-test))

(define-crc crc-24)
(test-equal 'success (crc-24-self-test))

(define-crc crc-64)
(test-equal 'success (crc-64-self-test))
(test-end)

;; Tests the other procedures

(test-begin "crc-low-level")
(test-equal #xE3069283
            (crc-32c-finish
             (crc-32c-update (crc-32c-update (crc-32c-init)
                                             (string->utf8 "12345"))
                             (string->utf8 "6789"))))

(test-equal #xE3069283
            (crc-32c-finish
             (crc-32c-update (crc-32c-update (crc-32c-init)
                                             (string->utf8 "XX12345") 2)
                             (string->utf8 "XX6789XX")  2 6)))

(test-equal #xE3069283
            (crc-32c (string->utf8 "123456789")))
(test-end)

;; Test the syntax for defining new CRCs

(test-begin "crc-syntax")
(define-crc crc-test (24 23 18 17 14 11 10 7 6 5 4 3 1 0)
            #xB704CE #f #f 0 #x21CF02)  ;CRC-24
(test-equal 'success (crc-test-self-test))
(test-end)

(test-begin "crc-syntax-verbose")
(let ()
  (define-crc crc-16/genibus
    (polynomial (16 12 5 0))
    (init #xffff)
    (ref-in #f)
    (ref-out #f)
    (xor-out #xffff)
    (check #xd64e))
  (test-equal 'success (crc-16/genibus-self-test)))
(let ()
  (define-crc crc-16/genibus
    (width 16)
    (polynomial #x1021)
    (init #xffff)
    (ref-in #f)
    (ref-out #f)
    (xor-out #xffff)
    (check #xd64e))
  (test-equal 'success (crc-16/genibus-self-test)))
(test-end)

(test-begin "crc-syntax-bit-oriented")
(let ()
  (define-bit-oriented-crc crc-6/darc
    (polynomial (6 4 3 0))
    (init 0)
    (ref-in #t)
    (ref-out #t)
    (xor-out 0)
    (check #x26))
  (define-bit-oriented-crc crc-82/darc
    (polynomial (82 77 76 71 67 66 56 52 48 40 36 34 24 22 18 10 4 0))
    (init 0)
    (ref-in #t)
    (ref-out #t)
    (xor-out 0)
    (check #x09ea83f625023801fd612))
  (test-equal 'success (crc-6/darc-self-test))
  (test-equal 'success (crc-82/darc-self-test)))
(let ()
  (define-bit-oriented-crc crc-6/darc
    (width 6)
    (polynomial #x19)
    (init 0)
    (ref-in #t)
    (ref-out #t)
    (xor-out 0)
    (check #x26))
  (define-bit-oriented-crc crc-82/darc
    (width 82)
    (polynomial #x0308c0111011401440411)
    (init 0)
    (ref-in #t)
    (ref-out #t)
    (xor-out 0)
    (check #x09ea83f625023801fd612))
  (test-equal 'success (crc-6/darc-self-test))
  (test-equal 'success (crc-82/darc-self-test)))
(test-end)


(exit (if (zero? (test-runner-fail-count (test-runner-get))) 0 1))
