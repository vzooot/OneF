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
    /// Hourly forecast at the next race's circuit, keyed by UTC hour.
    var weather: [Date: WeatherPoint] = [:]

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

            // Map and weather are bonuses — fetched after the essentials and
            // allowed to fail silently.
            if let race {
                async let map = TrackAPI.trackMap(
                    circuitId: race.circuit.circuitId,
                    season: race.season
                )
                async let forecast: [Date: WeatherPoint]? = {
                    guard let lat = race.circuit.location.lat,
                          let long = race.circuit.location.long else { return nil }
                    return try await WeatherAPI.hourlyForecast(latitude: lat, longitude: long)
                }()
                trackMap = try? await map
                weather = ((try? await forecast) ?? nil) ?? [:]
            } else {
                trackMap = nil
                weather = [:]
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
