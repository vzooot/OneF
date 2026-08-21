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
            StandingsTabView()
                .tabItem { Label("Standings", systemImage: "list.number") }
            NewsView()
                .tabItem { Label("News", systemImage: "newspaper.fill") }
        }
        .tint(Theme.f1Red)
    }
}
