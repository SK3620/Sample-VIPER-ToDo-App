//
//  Observable.swift
//  Sample-VIPER-ToDo-App
//
//  Created by 鈴木 健太 on 2026/09/20.
//

import Observation
import SwiftUI


@Observable
class MyClass {
    var value: Int = 4
    var value2: Int = 5
}

struct ContentView: View {
    @State var myClass: MyClass
    
    var body: some View {
        Text("\(myClass.value)")
            .onTapGesture {
                self.myClass.value += 1
            }
        
    }
}

// `@Observable` マクロを展開した結果、`Observable` プロトコルに自動適合されます
@Observable class Car: Observable {
    
    // ==========================================
    // 1. name プロパティの自動拡張部分
    // ==========================================
    @ObservationTracked
    var name: String = ""
    {
        // イニシャライザ（初期化）の制約：
        // 初期値が渡された際、表の `name` ではなく裏の `_name` を初期化する指定
        @storageRestrictions(initializes: _name)
        init(initialValue) {
            _name = initialValue
        }
        
        // 【読み取り（get）】値が読み出された瞬間に発火
        get {
            // 「今、誰（どのView）が name を読み取ったか」をレジストラ（監視メモ）に登録する
            // ここで、keyPathの住所（そのクラスのインスタンスのプロパティの住所/場所）を渡している
            access(keyPath: \.name)
            // 実際のデータは裏に隠してある `_name` から返す
            return _name
        }
        
        // 【書き込み（set）】値が代入された瞬間に発火
        set {
            // 値の変更処理全体を `withMutation` で包む
            withMutation(keyPath: \.name) {
                // 裏の変数に新しい値を代入する
                _name = newValue
            }
        }
        
        // 【直接参照・インプレース変更（_modify）】 `car.name.append("!")` などで効率よく変更するためのコルーチン
        _modify {
            // 変更前の読み取り登録
            access(keyPath: \.name)
            // 値が変わる直前に「今から変わるよ」と通知
            _$observationRegistrar.willSet(self, keyPath: \.name)
            
            // ブロックを抜ける直前（代入完了後）に必ず「変わったよ」と通知
            defer {
                _$observationRegistrar.didSet(self, keyPath: \.name)
            }
            // `_name` のメモリ参照を呼び出し元に一時的に貸し出す（yield）
            yield &_name
        }
    }

    // 実際の値を保持する「裏の変数」。
    // `@ObservationIgnored` をつけることで、この変数自体は二重で監視・自動展開されないようにする
    @ObservationIgnored private var _name: String = ""


    // ==========================================
    // 2. needsRepairs プロパティの自動拡張部分（nameと同様の仕組み）
    // ==========================================
    @ObservationTracked
    var needsRepairs: Bool = false
    {
        @storageRestrictions(initializes: _needsRepairs)
        init(initialValue) {
            _needsRepairs = initialValue
        }
        get {
            access(keyPath: \.needsRepairs)
            return _needsRepairs
        }
        set {
            withMutation(keyPath: \.needsRepairs) {
                _needsRepairs = newValue
            }
        }
        _modify {
            access(keyPath: \.needsRepairs)
            _$observationRegistrar.willSet(self, keyPath: \.needsRepairs)
            defer {
                _$observationRegistrar.didSet(self, keyPath: \.needsRepairs)
            }
            yield &_needsRepairs
        }
    }

    @ObservationIgnored private var _needsRepairs: Bool = false


    // ==========================================
    // 3. 監視・通知を管理するコア（裏方の仕掛け）
    // ==========================================
    
    /**
     「どの画面（View）が、どのプロパティを読んだか」という接続リストをメモしておくノート
     クラスインスタンスごとの配線（どのプロパティとどのUIパーツがつながっているか）を保持するメモ帳（レジストラ, ストレージを提供）
     データの変更の「追跡とアクセス」を管理？するためのストレージ
     */
    @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()

    /**
     _$observationRegistrar: マクロやコンパイラが「自動生成した隠し変数」を作るとき、ユーザー（開発者）が自分で書いた変数名とぶつからないようにするために、慣習として頭に _$ を付けます。
     
     keyPath: 「プロパティそのものの値」ではなく「プロパティの場所（住所 / 指し示している名前）」言い換えれば、実際の値が入っているロッカーの番号（住所/場所）みたいなこと nameという住所/場所をkeyPathとして渡す
     
     Member: ジェネリクス (keyPath: \.name)と指定すると → (keyPath: KeyPath<Car, String>)となる
     要するには、クラスのそれぞれのプロパティの型なんでも受け入れられるということ
     
     `self`: Car: self は　Car のことを指している（自身のインスタンス） 例えば、CarA CarB CarC ....
     
     subject (self): 「どのデータオブジェクトか」（例：Car のインスタンス carA）
     keyPath (keyPath): 「そのオブジェクト（インスタンス）のどの引き出し（場所）か」（例：\.name）
     この2つの組み合わせ（carA の \.name）によって、アプリ内の唯一のデータプロパティの住所を記録する
     */
    // 各プロパティの `get` から呼ばれるヘルパー関数。
    // レジストラに「自分のこのキーパス（プロパティ）が読まれました」と登録を依頼する
    internal nonisolated func access<Member>(keyPath: KeyPath<Car, Member>) {
        _$observationRegistrar.access(self, keyPath: keyPath)
    }

    // 各プロパティの `set` から呼ばれるヘルパー関数。
    // レジストラに「これからこのキーパスを変更するので、繋がっている（紐づいている）Viewへ通知を出してください」と依頼する
    internal nonisolated func withMutation<Member, MutationResult>(
        keyPath: KeyPath<Car, Member>,
        _ mutation: () throws -> MutationResult
    ) rethrows -> MutationResult {
        try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }
}

/**
 KeyPath
 一言で言うと、「データそのもの（値）」ではなく「データの場所（プロパティという名の引き出し）」を指し示すパス（経路住所） のことです。
 struct Dog {
     var name: String
     var age: Int
 }

 var dog = Dog(name: "いぬ", age: 5)

 // 値の読み取り
 let keyPath: KeyPath<Dog, String> = \.name
 print(dog[keyPath: keyPath]) // いぬ

 // 書き込み
 let writableKeyPath: WritableKeyPath<Dog, String> = \.age
 dog[keyPath: writableKeyPath] = 10
 print(dog.age) // 10
 */
