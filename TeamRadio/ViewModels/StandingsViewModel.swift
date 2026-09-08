import Foundation
import Observation

@Observable
@MainActor
final class StandingsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var phase: Phase = .loading
    var drivers: [DriverStanding] = []
    var constructors: [ConstructorStanding] = []

    private var hasLoadedOnce = false

    func load() async {
        if !hasLoadedOnce { phase = .loading }
        do {
            async let allDrivers = F1API.driverStandings(limit: 40)
            async let allTeams = F1API.constructorStandings(limit: 20)

            let (driverList, teamList) = try await (allDrivers, allTeams)
            drivers = driverList
            constructors = teamList
            phase = .loaded
            hasLoadedOnce = true
        } catch {
            if !hasLoadedOnce {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}
