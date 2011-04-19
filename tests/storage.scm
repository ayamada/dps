;;
;; basic tests
;;

(use gauche.test)

(test-start "storage.scm")
(load "../lib/dps/storage.scm")
(test-module 'dps.storage)
(test-end)
