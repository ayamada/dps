;;
;; basic tests
;;

(add-load-path "../lib")
(use gauche.test)

(test-start "dps.scm")
(load "../lib/dps.scm")
(test-module 'dps)
(test-end)
