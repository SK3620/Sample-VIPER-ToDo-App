//
//  PropertyWrapper.swift
//  Sample-VIPER-ToDo-App
//
//  Created by 鈴木 健太 on 2026/09/10.
//

import SwiftUI

struct Book: Identifiable {
    var id: Int = 1
    var title = "タイトル"
}

struct Hoge: View {
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss

    // @State<String> private var text = "Hello, World!"
    @State private var text = "Hello, World!"
    @State(wrappedValue: "Hello, World!") var text2
    
    @State private var books = [Book(), Book(), Book()]
    
    // 変数に適用することができる 変数に何かをセットすると、違う値がセットされて、それが返却されてくる
    @HelloWorld var message: String
        
    var body: some View {
        VStack {
            Text("Hello, World!")
            Text("Hello, World!")
            Text("Hello, World!")
            
            TextField("名前を変更", text: $text)
        }
    }
}

// @propertyWrapper: 変数をラッピングして、アクセス（get/set）を制御するための仕組み
@propertyWrapper struct HelloWorld {
    private var text: String
    
    /**
     projectedValue: wrappedValueを読み取った時に、返却する、wrappedValueの追加情報的なやつ。 「$」をつけた時に返す付加情報（今回は変更フラグ）
     
     以下の二つの初期化処理と同じもの。
     public init(wrappedValue value: Value)
     public init(initialValue value: Value)
     */
    var projectedValue: Bool
    
    // wrappedValue を受け取る init を用意する
    public init(wrappedValue: String) {
        self.text = wrappedValue
        self.projectedValue = false
    }
    
    // wrappedValue を受け取る init を用意する
    public init(initialValue: String) {
        self.text = initialValue
        self.projectedValue = false
    }
    
    // wrappedValue を受け取る init を用意する
    public init(projectedValue: String) {
        self.text = projectedValue
        self.projectedValue = false
    }
    
    /// wrappedValue: 変数への読み書き時に動くメインの値（窓口）
    var wrappedValue: String {
        get {
            return text
        }
        set {
            if newValue == "世界" {
                text = "こんにちは, \(newValue)!"
                projectedValue = true
            } else {
                text = "Hello, \(newValue)!"
                projectedValue = false
            }
            // ここでSwiftUIのViewを再描画する処理みたいなのが走るようになっっている？？
        }
    }
}

class Hello {

    
    @HelloWorld(wrappedValue: "Hello, World!") var str: String
    @HelloWorld var str2: String = "Good Night"

    /**
     @HelloWorld(wrappedValue: "Hello, World!") var str: String
     @HelloWorld var str2: String = "Good Night"
     → どちらもやっていることは同じ初期化処理。
     */
    func sayHello() {
        print(str)        // Hello, World!
        print("\($str)")  // false
        str = "世界"
        print(str)        // こんにちは, 世界!
        print("\($str)")  // true
    }
    
    
}



/*
/// `@State` は、Viewで扱う「値（状態）」を保持・管理するための仕組みです。
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@frozen
@propertyWrapper
public struct State2<Value> : DynamicProperty {

    // ==========================================
    // 1. 初期化（値のセット）
    // ==========================================
    
    /// `@State private var isPlaying = false` と初期値を渡したときに、
    /// SwiftUI が裏側で自動的に呼び出す処理です。
    public init(wrappedValue value: Value)

    /// 上の `init(wrappedValue:)` とまったく同じ役割の初期化処理です。
    /// This initializer has the same behavior as the init(wrappedValue:) initializer.
    public init(initialValue value: Value)


    // ==========================================
    // 2. メインの値（wrappedValue）
    // ==========================================
    
    /// 読み書きする値の「本体」です。
    ///
    /// 普通に変数を使う（`isPlaying.toggle()` など）と、この値が動きます。
    /// 値が変更されると、SwiftUI は「画面（View）を再描画」します。
    public var wrappedValue: Value { get nonmutating set }


    // ==========================================
    // 3. 投影値（projectedValue）
    // ==========================================
    
    /// 変数の頭に「`$`」をつけたとき（`$isPlaying`）に取り出せる値です。
    ///
    /// 他のボタンや画面パーツに値を渡して「双方向に読み書き（連携）」させるための
    /// `Binding`（バインディング）を返します。
    public var projectedValue: Binding<Value> { get }
}
*/
