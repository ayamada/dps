;;; dps main module

;;; TODO: 将来は、 dps.server や dps.client 等に分割するかも

;;; TODO: 将来はスレッド化しそうなので、スレッド化する場合は、
;;;       opened? closed? のチェック/変更は、セマフォ等を使うようにする必要あり

(define-module dps
  (use srfi-1)
  (use text.tree)
  (use gauche.charconv)
  (use gauche.sequence)
  (use gauche.threads)
  (use c-wrapper)
  (use file.util)

  (c-load-library "libzmq.so")
  (c-include "zmq.h")
  (c-load-library "libuuid.so")
  (c-include "uuid/uuid.h")

  (use file.util)

  ;(use dps.spec) ; TODO: 更に子モジュールでバージョニングする
  ;(use dps.storage)
  ;(use dps.slrrf) ; sexprs like reversed rfc822 format
  (export
    <dps>
    ;; dpsアクセスの為のインターフェースを考え直す必要あり
    ;; dbm類似のopen<->close方式とする？
    ;; - この場合、<dps>インスタンスがcloseされてしまってるかどうかを
    ;;   method呼び出し時毎にチェックする必要が出る
    ;; それとも、with-*方式とする？
    ;; - with-*方式にする場合、(make <dps> ...)する必要がなくなる代わりに、
    ;;   with-*時にパラメータを渡す事になる。
    ;;   また、継続でwith-*を出入りした時の扱いをどうするか
    ;;   ちゃんと考える必要がある
    ;; 両方用意する？とりあえず内部的には、両方用意しても問題はなさそうだが
    ;; - 他にもっと良いインターフェースがあるかもしれない。
    ;;   が、今はとりあえず両方という事で
    ;;   (実際に使われる状況がどうなるか微妙なので)

    ;; 上記の通り、とりあえず最初はdbmを参考にインターフェースを用意する
    dps-open
    dps-close

    ;; 古いmainエントリ
    dps-main
    ))
(select-module dps)


;;; 各種の内部抽象クラスの定義
;;; TODO: あとで
;;; TODO: 別ファイルに移動する

;;; readerおよびwriterの定義
;;; TODO: あとで




;;; 実ストレージ部の定義
;;; TODO: 別ファイルに移動する

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
   ;(journal-log :init-value #f)
   (opened? :init-value #f)
   (closed? :init-value #f)
   ))

(define-method initialize ((self <dps>) initargs)
  ;; TODO: data-dir の検査など
  (next-method))



(define-method dps-open ((self <dps>))
  (when opened?
    (error "already opened" self))
  (when closed?
    (error "assertion (closed?)" self))
  ;; TODO: ここからはトランザクション安全にする必要あり
  (set! (~ self'key->uuid-table)
    (dbm-open (~ self'dbm-type)
              :path (build-path (~ self'data-dir) "key2uuid")
              :key-convert (list (cute write-to-string <> write/ss)
                                 read-from-string)
              :value-convert #f
              :rw-mode :write))
  (set! (~ self'uuid->val-table)
    (dbm-open (~ self'dbm-type)
              :path (build-path (~ self'data-dir) "uuid2val")
              :key-convert #f
              :value-convert #f
              :rw-mode :write))
  (set! (~ self'system-table)
    (dbm-open (~ self'dbm-type)
              :path (build-path (~ self'data-dir) "system")
              :key-convert #f
              :value-convert (list (cute write-to-string <> write/ss)
                                   read-from-string)
              :rw-mode :write))
  ;; TODO: versionやストレージ等のチェックをしてもよい
  ;; openしたので、フラグを立てる
  (set! (~ self'opened?) #t))
  self)

(define-method dps-close ((self <dps>))
  (unless opened?
    (error "not opened" self))
  (when closed?
    (error "already closed" self))
  ;; TODO: ここからはトランザクション安全にする必要あり
  ;; TODO: 何らかの非同期処理が完了していない場合は、待つ必要あり
  (dbm-close (~ sefl'key->uuid-table))
  (dbm-close (~ sefl'uuid->val-table))
  (dbm-close (~ sefl'system-table))
  (set! (~ sefl'key->uuid-table) #f)
  (set! (~ sefl'uuid->val-table) #f)
  (set! (~ sefl'system-table) #f)
  ;; closeしたので、フラグを立てる
  (set! (~ self'closed?) #t))
  self)



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
