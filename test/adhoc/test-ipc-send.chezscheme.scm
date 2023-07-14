(import (micro dagopoly)
    (micro fs)
	(micro stream)
	(micro dagopoly-python))
(current-io
 '((relfPythonipc . "../dagopoly-py/test/autobin/test-ipc-receive.py")))
(define b1 (block-python "expr3"))
(display (format "sig=~s\n" (block-sig b1)))
(display (format "get=~s\n" (s->list (block-get b1))))
