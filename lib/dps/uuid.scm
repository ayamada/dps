;;; dps uuid module

(define-module dps.uuid
  (use srfi-1)
  (use gauche.sequence)

  (use c-wrapper)
  (c-load-library "libuuid.so")
  (c-include "uuid/uuid.h")

  (export
    generate-uuid-string
    ))
(select-module dps.uuid)


;; TODO: もっと手続きを用意すべき？？？


(define (generate-uuid-string)
  (let ((uuid (make <uuid_t>))
        (buf (make (c-array <c-char> 37)))
        )
    (uuid_generate uuid)
    (uuid_unparse uuid (ptr buf))
    (x->string buf)))


;;;===================================================================

;; Local variables:
;; mode: scheme
;; end:
;; vim: set ft=scheme fenc=utf-8:
