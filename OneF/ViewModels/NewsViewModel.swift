import Foundation
import Observation

@Observable
@MainActor
final class NewsViewModel {
    var items: [NewsItem] = []
    var isLoading = false
    private var hasLoadedOnce = false

    func load() async {
        if !hasLoadedOnce { isLoading = true }
        let latest = await NewsService.latest()
        if !latest.isEmpty || !hasLoadedOnce {
            items = latest
        }
        isLoading = false
        hasLoadedOnce = true
    }
}
