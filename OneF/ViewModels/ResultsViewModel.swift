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
    /// Rounds shown in the picker: every completed race, plus the current
    /// weekend as soon as any of its sessions has a classification.
    var pickerRaces: [Race] = []
    var selectedRound: String?
    /// Calendar entry for the selected round (name, circuit, sprint flag).
    var calendarRace: Race?
    var raceResults: [RaceResult]?
    var sprintResults: [RaceResult]?
    var qualifyingResults: [QualifyingResult]?
    var constructorStandings: [ConstructorStanding] = []
    /// True while fetching a different round after the initial load.
    var isSwitching = false

    private var season: [Race] = []
    private var hasLoadedOnce = false

    func load() async {
        if !hasLoadedOnce { phase = .loading }
        do {
            async let latest = F1API.lastRaceResults()
            async let calendar = F1API.season()
            async let teams = F1API.constructorStandings(limit: 5)

            let (last, races, cs) = try await (latest, calendar, teams)
            season = races
            constructorStandings = cs

            let lastRound = last?.roundNumber ?? 0
            var picker = races.filter { $0.roundNumber <= lastRound }

            // The ongoing weekend joins the picker once quali or sprint has
            // run, so per-session results appear before the grand prix does.
            var currentPartial: (race: Race, quali: [QualifyingResult]?, sprint: [RaceResult]?)?
            if let current = races.first(where: { $0.roundNumber == lastRound + 1 }) {
                async let quali = F1API.qualifying(round: current.round)
                async let sprint = current.isSprintWeekend ? F1API.sprintResults(round: current.round) : nil
                let q = (try? await quali)?.qualifyingResults
                let s = (try? await sprint)?.sprintResults
                if q?.isEmpty == false || s?.isEmpty == false {
                    picker.append(current)
                    currentPartial = (current, q, s)
                }
            }
            pickerRaces = picker

            if let partial = currentPartial {
                // Default to the live weekend.
                selectedRound = partial.race.round
                calendarRace = partial.race
                raceResults = nil
                qualifyingResults = partial.quali
                sprintResults = partial.sprint
            } else if let last {
                selectedRound = last.round
                calendarRace = races.first { $0.round == last.round } ?? last
                raceResults = last.results
                async let quali = F1API.qualifying(round: last.round)
                async let sprint = (calendarRace?.isSprintWeekend == true) ? F1API.sprintResults(round: last.round) : nil
                qualifyingResults = (try? await quali)?.qualifyingResults
                sprintResults = (try? await sprint)?.sprintResults
            }

            phase = .loaded
            hasLoadedOnce = true
        } catch {
            if !hasLoadedOnce {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    /// Loads the classifications of another round from the picker.
    func select(round: String) async {
        guard round != selectedRound else { return }
        guard let race = pickerRaces.first(where: { $0.round == round }) ?? season.first(where: { $0.round == round }) else { return }
        selectedRound = round
        calendarRace = race
        isSwitching = true
        defer { isSwitching = false }

        async let results = F1API.raceResults(round: round)
        async let quali = F1API.qualifying(round: round)
        async let sprint = race.isSprintWeekend ? F1API.sprintResults(round: round) : nil

        raceResults = (try? await results)?.results
        qualifyingResults = (try? await quali)?.qualifyingResults
        sprintResults = (try? await sprint)?.sprintResults
    }
}
