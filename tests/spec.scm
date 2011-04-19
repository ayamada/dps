;;
;; basic tests
;;

(add-load-path "../lib")
(use gauche.test)

(test-start "spec.scm")
(load "../lib/dps/spec.scm")
(test-module 'dps.spec)
(test-end)
