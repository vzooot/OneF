import Foundation
import Observation

@Observable
@MainActor
final class ResultsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var phase: Phase = .loading
    var raceWithResults: Race?
    var raceWithQualifying: Race?
    var constructorStandings: [ConstructorStanding] = []

    private var hasLoadedOnce = false

    func load() async {
        if !hasLoadedOnce { phase = .loading }
        do {
            async let results = F1API.lastRaceResults()
            async let qualifying = F1API.lastQualifying()
            async let constructors = F1API.constructorStandings(limit: 5)

            let (race, quali, teams) = try await (results, qualifying, constructors)
            raceWithResults = race
            raceWithQualifying = quali
            constructorStandings = teams
            phase = .loaded
            hasLoadedOnce = true
        } catch {
            if !hasLoadedOnce {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}
