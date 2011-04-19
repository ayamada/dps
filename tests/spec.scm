;;
;; basic tests
;;

(use gauche.test)

(test-start "spec.scm")
(load "../lib/dps/spec.scm")
(test-module 'dps.spec)
(test-end)
