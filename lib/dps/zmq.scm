;;; dps zmq module

(define-module dps.zmq
  (use srfi-1)

  (use c-wrapper)
  (c-load-library "libzmq.so")
  (c-include "zmq.h")

  (export
    call-with-zmq-context
    ))
(select-module dps.zmq)


(define (call-with-zmq-context proc)
  ;; TODO: contextはあまり使われないなら、陽に渡さずに、
  ;;       parameter等に保持した方がいい気がする、が、要調査
  ;; TODO: ↓のコメントアウトされているsocket回りを別のところに移動
  (let* ((context (zmq_init 1))
         ;; TODO: unwind-protectに含める部分をよく考える必要あり
         ;(socket (zmq_socket context ZMQ_REP))
         ;(rc (zmq_bind socket "tcp://127.0.0.1:5555"))
         )
    (unwind-protect
      (proc context)
      ;(zmq_close socket)
      (zmq_term context))))



;;;===================================================================

;; Local variables:
;; mode: scheme
;; end:
;; vim: set ft=scheme fenc=utf-8:
