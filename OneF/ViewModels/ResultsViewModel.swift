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
    /// Every round that has been raced, in calendar order.
    var completedRaces: [Race] = []
    var selectedRound: String?
    var raceWithResults: Race?
    var raceWithQualifying: Race?
    var constructorStandings: [ConstructorStanding] = []
    /// True while fetching a different round after the initial load.
    var isSwitching = false

    private var hasLoadedOnce = false

    func load() async {
        if !hasLoadedOnce { phase = .loading }
        do {
            async let latest = F1API.lastRaceResults()
            async let calendar = F1API.season()
            async let teams = F1API.constructorStandings(limit: 5)

            let (last, races, cs) = try await (latest, calendar, teams)
            constructorStandings = cs
            if let last {
                completedRaces = races.filter { $0.roundNumber <= last.roundNumber }
                selectedRound = last.round
                raceWithResults = last
                raceWithQualifying = try? await F1API.qualifying(round: last.round)
            }
            phase = .loaded
            hasLoadedOnce = true
        } catch {
            if !hasLoadedOnce {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    /// Loads the classification of another completed round.
    func select(round: String) async {
        guard round != selectedRound else { return }
        selectedRound = round
        isSwitching = true
        defer { isSwitching = false }

        async let results = F1API.raceResults(round: round)
        async let qualifying = F1API.qualifying(round: round)
        if let race = try? await results {
            raceWithResults = race
        }
        raceWithQualifying = try? await qualifying
    }
}
