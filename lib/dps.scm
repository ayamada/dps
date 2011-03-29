;;; dps main module

;;; TODO: 将来は、 dps.server や dps.client 等に分割するかも

(define-module dps
  (use srfi-1)

  ;; ↓for sample
  (use text.tree)
  (use gauche.charconv)

  (use dps.spec)
  (use dps.storage)
  (use dps.uuid)
  (use dps.zmq)

  (extend
    dps.spec
    dps.storage
    )
  (export
    <dps>
    dps-main
    ))
(select-module dps)


(define (get-words)
  (call-with-zmq-context
    (lambda (context)
      (tree->string
        (list
          "まだです\n"
          (generate-uuid-string))))))


(define-method dps-main ((self <dps>) . keywords)
  (print (ces-convert (get-words) 'utf-8 'euc-jp))
  0)


;;;===================================================================

;; Local variables:
;; mode: scheme
;; end:
;; vim: set ft=scheme fenc=utf-8:
