;;; dps storage module

;;; TODO: 将来はスレッド化しそうなので、スレッド化する場合は、
;;;       opened? closed? のチェック/変更は、セマフォ等を使うようにする必要あり

(define-module dps.storage
  (use srfi-1)
  (use file.util)

  (use dps.swmflrr)

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
    ))
(select-module dps.storage)


;;; 実ストレージ部の定義

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
  (set! (~ self'opened?) #t)
  self)

(define-method dps-close ((self <dps>))
  (unless opened?
    (error "not opened" self))
  (when closed?
    (error "already closed" self))
  ;; TODO: ここからはトランザクション安全にする必要あり
  ;; TODO: 何らかの非同期処理が完了していない場合は、待つ必要あり
  (dbm-close (~ self'key->uuid-table))
  (dbm-close (~ self'uuid->val-table))
  (dbm-close (~ self'system-table))
  (set! (~ self'key->uuid-table) #f)
  (set! (~ self'uuid->val-table) #f)
  (set! (~ self'system-table) #f)
  ;; closeしたので、フラグを立てる
  (set! (~ self'closed?) #t)
  self)




;;;===================================================================

;; Local variables:
;; mode: scheme
;; end:
;; vim: set ft=scheme fenc=utf-8:
