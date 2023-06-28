(import (micro dagopoly)
	(micro dagopoly-python))
(current-io
 '((relfPythonipc . "../datriples/dagopoly/test/autobin/testipc1.py")))
(define b1 (block-python "expr3"))
(display (format "sig=~a\n" (block-sig b1)))
(display (format "get=~a\n" (s->list (block-get b1))))
