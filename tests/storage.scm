;;
;; basic tests
;;

(add-load-path "../lib")
(use gauche.test)

(test-start "storage.scm")
(load "../lib/dps/storage.scm")
(test-module 'dps.storage)
(test-end)
