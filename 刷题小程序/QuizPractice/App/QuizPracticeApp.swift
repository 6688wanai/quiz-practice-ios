import SwiftUI

@main
struct QuizPracticeApp: App {
    @StateObject private var store = QuizStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
