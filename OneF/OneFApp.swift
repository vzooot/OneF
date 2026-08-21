import SwiftUI

@main
struct OneFApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label("Countdown", systemImage: "flag.checkered") }
                .tag(0)
            NewsView()
                .tabItem { Label("News", systemImage: "newspaper.fill") }
                .tag(1)
        }
        .tint(Theme.f1Red)
    }
}
