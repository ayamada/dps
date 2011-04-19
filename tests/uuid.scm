;;
;; basic tests
;;

(use gauche.test)

(test-start "uuid.scm")
(load "../lib/dps/uuid.scm")
(test-module 'dps.uuid)
(test-end)
