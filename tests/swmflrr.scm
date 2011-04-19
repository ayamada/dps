;;
;; basic tests
;;

(use gauche.test)

(test-start "swmflrr.scm")
(load "../lib/dps/swmflrr.scm")
(test-module 'dps.swmflrr)
(test-end)
