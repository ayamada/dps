;;
;; basic tests
;;

(add-load-path "../lib")
(use gauche.test)

(test-start "zmq.scm")
(load "../lib/dps/zmq.scm")
(test-module 'dps.zmq)
(test-end)
