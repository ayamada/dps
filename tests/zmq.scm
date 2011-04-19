;;
;; basic tests
;;

(use gauche.test)

(test-start "zmq.scm")
(load "../lib/dps/zmq.scm")
(test-module 'dps.zmq)
(test-end)
