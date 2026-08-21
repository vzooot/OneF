import Foundation
import Observation

@Observable
@MainActor
final class RaceViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var phase: Phase = .loading
    var nextRace: Race?
    var season: [Race] = []
    var standings: [DriverStanding] = []
    var trackMap: TrackMap?

    private var hasLoadedOnce = false

    func load() async {
        if !hasLoadedOnce { phase = .loading }
        do {
            async let next = F1API.nextRace()
            async let calendar = F1API.season()
            async let top = F1API.driverStandings(limit: 5)

            let (race, races, drivers) = try await (next, calendar, top)
            nextRace = race
            season = races
            standings = drivers
            phase = .loaded
            hasLoadedOnce = true

            // The circuit map is a bonus — fetched after the essentials, and
            // allowed to fail silently (new circuits have no map data yet).
            if let race {
                trackMap = try? await TrackAPI.trackMap(
                    circuitId: race.circuit.circuitId,
                    season: race.season
                )
            } else {
                trackMap = nil
            }
        } catch {
            // Keep stale data on screen if a refresh fails; only surface the
            // error state when we have nothing to show at all.
            if !hasLoadedOnce {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}
