// MARK: - @Observable / withObservationTracking 動作シーケンス解説
/*
 =========================================================================================
  【要点まとめ】
  1. 画面描画（bodyやList内部パーツ）の実行中に、直接参照されたプロパティ（get）だけが自動で監視対象になる。
  2. そのプロパティが変更（set）されると、事前に渡された「onChange クロージャ（再描画命令）」が発火する。
 =========================================================================================

  @Observable における「監視登録 → 読込(get) → 書き換え(set) → ピンポイント再描画」の内部メカニズム
 =========================================================================================
 
 【全体シーケンス】
 
   1. 監視準備      : withObservationTracking 呼び出し時、「apply（描画処理）」と「onChange（再描画命令）」がセットされる
   2. 読込 & 記録   : Text(model.name) 実行時に get/access() が動いて「一時メモ用紙」にプロパティを記録
   3. 配線帳へ登録  : 評価終了後、一時メモ用紙の記録と「onChange（再描画命令）」をペアにして「配線帳(ObservationRegistrar)」へ登録
   4. 書き換え&検索 : model.name = "新" 実行時に set/withMutation() が動いて配線帳から「onChange」を検索
   5. ピンポイント再描画: 配線帳から取り出した「onChange（再描画命令）」を実行し、対象 View を狙い撃ち発火
 
 -----------------------------------------------------------------------------------------
 【各ステップの詳細解説】
 
  1. 監視の準備（一時メモ用紙の設置と onChange の受け取り）
     - タイミング : View の body（または List 内の遅延評価クロージャ）が実行される直前。
     - 動作       : ① SwiftUI は `withObservationTracking` を呼び出す。
                    ② 第1引数に `apply`（画面描画処理）、第2引数に `onChange`（値変更時に画面を再更新する処理）を受け取る。
                    ③ 作業スレッド領域（`_ThreadLocal`）に空の「一時メモ用紙（`_AccessList`）」をセットする。
 
  2. 値の読み込みと記録（get / access）
     - タイミング : `apply()` 実行の中で `Text(model.name)` などのプロパティ参照が走る瞬間。
     - 動作       : ① `model.name` の `get` アクセサが発火。
                    ② `get` 内の `access(keyPath: \.name)` が呼ばれる。
                    ③ `access` はスレッド上の一時メモ用紙を見つけ、
                       「`model` インスタンス ＋ `\.name`」の組み合わせを自動書き足し。
 
  3. 配線帳への登録（installTracking）
     - タイミング : `apply()`（描画評価）の実行が完了した直後。
     - 動作       : ① `withObservationTracking` が一時メモ用紙を回収。
                    ② メモ用紙に溜まったプロパティと、ステップ1で渡された `onChange`（再描画命令）をセットで配線帳（`ObservationRegistrar`）へ登録。
                       ➔ 「`\Model.name` ➔ 受け取っていた `onChange` 関数」
 
  4. 値の書き換えと検索（set / withMutation）
     - タイミング : コード上で `model.name = "新しい名前"` が実行された時。
     - 動作       : ① `model.name` の `set` アクセサが発火。
                    ② `set` 内の `withMutation(keyPath: \.name)` が動く。
                    ③ 配線帳を開き、`\Model.name` に紐づいている `onChange` を検索。
 
  5. ピンポイント再描画
     - タイミング : `withMutation`（値の更新通知）発火時。
     - 動作       : 配線帳から取り出した `onChange` クロージャを実行。
                    ※この `onChange` が発火することで、プロパティを直接参照していた
                      対象 View（List 内の 1 行の Text 等）の body のみが狙い撃ちで再実行される。
 
 -----------------------------------------------------------------------------------------
 【一言まとめ】
  - get (読み込み) : 触られたプロパティを「一時メモ用紙」に溜め、渡された「onChange（再描画命令）」と共に「配線帳」へ一括登録する
  - set (書き換え) : 配線帳から該当キーを探して、ペアになっている「onChange」を実行（再描画を直接発火）させる
 =========================================================================================
 */

/*
 【Swift標準ライブラリの実装コード解説】

 public func withObservationTracking<T>(
      _ apply: () -> T,
      onChange: @autoclosure () -> @Sendable () -> Void
    ) -> T {
      // 【ステップ1 & 2】apply()（＝Viewやクロージャの描画評価）を実行。
      //  スレッド上にセットされた「一時メモ用紙」に、発火した get/access() のプロパティ記録を集める。
      let accessListResult = generateAccessList(apply)
      
      // 【ステップ3】一時メモ用紙からプロパティ一覧を取り出し、
      //  引数で渡された `onChange`（再描画命令）と紐づけて「配線帳」へ登録する。
      if let accessList = accessListResult.accessList {
        ObservationTracking._installTracking(accessList, onChange: onChange())
      }
      
      // 生成された View や要素の描画結果（T）をそのまま返す
      return accessListResult.result
    }
 */
