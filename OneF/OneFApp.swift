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
    @Environment(\.scenePhase) private var scenePhase
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                LiveActivityManager.refresh()
            }
        }
    }
}
