;;; dps main module

;;; TODO: 将来は、 dps.server や dps.client 等に分割するかも

(define-module dps
  (use srfi-1)
  (use text.tree)
  (use gauche.charconv)
  (use gauche.sequence)
  (use gauche.threads)
  (use c-wrapper)
  (use dbm.fsdbm)
  (c-load-library "libzmq.so")
  (c-include "zmq.h")
  (c-load-library "libuuid.so")
  (c-include "uuid/uuid.h")
  (export
    <dps>
    dps-main
    ))
(select-module dps)


(define-class <dps> ()
  (
   ;; initial parameter
   (dbm-type :init-keyword :dbm-type
             :init-form (error "dbm-type not found"))
   (data-dir :init-keyword :data-dir
             :init-form (error "data-dir not found"))
   ;; internal parameter
   (key->uuid-table :init-value #f)
   (uuid->val-table :init-value #f)
   (system-table :init-value #f)
   (journal-log :init-value #f)
   ))

(define-method initialize ((self <dps>) initargs)
  ;; TODO: data-dir の検査など
  (next-method))




;; TODO: zmq回りはあとで別モジュールに分ける筈なので、
;;       それを前提として手続き等を分離しておく事

(define (generate-uuid-string)
  (let ((uuid (make <uuid_t>))
        (buf (make (c-array <c-char> 37)))
        )
    (uuid_generate uuid)
    (uuid_unparse uuid (ptr buf))
    (x->string buf)))


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


(define (get-words)
  ;; TODO: ストレージを用意する必要がある
  ;; ストレージについて:
  ;; - スレッドを使い、REQを出すプロセスと、RESを返すプロセスを生成し、
  ;;   inprocで通信させる
  ;; -- スレッドじゃなく、別プロセスにした方がいいのでは？
  ;; - ストレージ本体はdbmとする
  ;; TODO: ストレージに先にデータを入れておく必要がある。どうする？
  ;;       - 書き込むインターフェース(しょぼくてok)を先に用意する？
  ;;       -- 最終的にはこれも必要になるので、こっちが先でよさそう
  (call-with-zmq-context
    (lambda (context)
      (tree->string
        (list
          "まだです\n"
          (generate-uuid-string))))))


(define-method dps-main ((self <dps>) . keywords)
  ;; あとで
  ;; まず、最小で動くコードを書く必要がある。
  ;; それは、どのような動作をするコード？
  ;; - ストレージから格言をランダムに取り出し、printするだけのコード
  ;; -- まだ重み付けやメタ情報の付与は考えなくてよい
  (print (ces-convert (get-words) 'utf-8 'euc-jp))
  0)


;;;===================================================================

;; Local variables:
;; mode: scheme
;; end:
;; vim: set ft=scheme fenc=utf-8:
