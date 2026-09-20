import SwiftUI
import Observation

@main
struct HogeHoge: App {
    var body: some Scene {
        WindowGroup {
            MyView()
        }
    }
}

// 1. @Observable な Book モデル
@Observable
class Book2: Identifiable {
    let id = UUID()
    var title: String
    
    init(title: String) {
        self.title = title
    }
}

struct MyView: View {
    var model = Book2(title: "Hello")
    
    var body: some View {
                let _ = print("かかか")
        
        Text(model.title)
        
        Button {
            model.title = "あああ"
        } label: {
            Text("変更ボタン")
        }
    }
}
