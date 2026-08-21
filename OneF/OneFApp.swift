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
            ResultsView()
                .tabItem { Label("Results", systemImage: "trophy.fill") }
            NewsView()
                .tabItem { Label("News", systemImage: "newspaper.fill") }
        }
        .tint(Theme.f1Red)
    }
}
