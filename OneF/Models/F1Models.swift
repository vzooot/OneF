import Foundation

// MARK: - Ergast/Jolpica response envelope

struct ErgastResponse: Decodable {
    let mrData: MRData

    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

struct MRData: Decodable {
    let raceTable: RaceTable?
    let standingsTable: StandingsTable?

    enum CodingKeys: String, CodingKey {
        case raceTable = "RaceTable"
        case standingsTable = "StandingsTable"
    }
}

struct RaceTable: Decodable {
    let season: String?
    let races: [Race]

    enum CodingKeys: String, CodingKey {
        case season
        case races = "Races"
    }
}

struct StandingsTable: Decodable {
    let standingsLists: [StandingsList]

    enum CodingKeys: String, CodingKey {
        case standingsLists = "StandingsLists"
    }
}

struct StandingsList: Decodable {
    let round: String?
    let driverStandings: [DriverStanding]

    enum CodingKeys: String, CodingKey {
        case round
        case driverStandings = "DriverStandings"
    }
}

// MARK: - Race & sessions

struct Race: Decodable, Identifiable, Equatable {
    let season: String
    let round: String
    let raceName: String
    let circuit: Circuit
    let date: String
    let time: String?
    let firstPractice: SessionTime?
    let secondPractice: SessionTime?
    let thirdPractice: SessionTime?
    let qualifying: SessionTime?
    let sprint: SessionTime?
    let sprintQualifying: SessionTime?

    enum CodingKeys: String, CodingKey {
        case season, round, raceName, date, time
        case circuit = "Circuit"
        case firstPractice = "FirstPractice"
        case secondPractice = "SecondPractice"
        case thirdPractice = "ThirdPractice"
        case qualifying = "Qualifying"
        case sprint = "Sprint"
        case sprintQualifying = "SprintQualifying"
    }

    var id: String { "\(season)-\(round)" }

    var roundNumber: Int { Int(round) ?? 0 }

    /// UTC start of the grand prix itself.
    var startDate: Date? { ErgastDate.parse(date: date, time: time) }

    var isSprintWeekend: Bool { sprint != nil || sprintQualifying != nil }

    /// All weekend sessions in chronological order, race included.
    var sessions: [WeekendSession] {
        var items: [WeekendSession] = []
        func add(_ kind: WeekendSession.Kind, _ st: SessionTime?) {
            guard let st, let d = ErgastDate.parse(date: st.date, time: st.time) else { return }
            items.append(WeekendSession(kind: kind, date: d))
        }
        add(.practice1, firstPractice)
        add(.practice2, secondPractice)
        add(.practice3, thirdPractice)
        add(.sprintQualifying, sprintQualifying)
        add(.sprint, sprint)
        add(.qualifying, qualifying)
        if let d = startDate {
            items.append(WeekendSession(kind: .race, date: d))
        }
        return items.sorted { $0.date < $1.date }
    }

    static func == (lhs: Race, rhs: Race) -> Bool { lhs.id == rhs.id }
}

struct SessionTime: Decodable {
    let date: String
    let time: String?
}

struct WeekendSession: Identifiable {
    enum Kind: String {
        case practice1 = "Practice 1"
        case practice2 = "Practice 2"
        case practice3 = "Practice 3"
        case sprintQualifying = "Sprint Quali"
        case sprint = "Sprint"
        case qualifying = "Qualifying"
        case race = "Race"

        var short: String {
            switch self {
            case .practice1: "FP1"
            case .practice2: "FP2"
            case .practice3: "FP3"
            case .sprintQualifying: "SQ"
            case .sprint: "SPR"
            case .qualifying: "Q"
            case .race: "RACE"
            }
        }
    }

    let kind: Kind
    let date: Date
    var id: String { kind.rawValue }
}

struct Circuit: Decodable {
    let circuitId: String
    let circuitName: String
    let location: CircuitLocation

    enum CodingKeys: String, CodingKey {
        case circuitId, circuitName
        case location = "Location"
    }
}

struct CircuitLocation: Decodable {
    let lat: String?
    let long: String?
    let locality: String
    let country: String
}

// MARK: - Standings

struct DriverStanding: Decodable, Identifiable {
    let position: String
    let points: String
    let wins: String
    let driver: Driver
    let constructors: [Constructor]

    enum CodingKeys: String, CodingKey {
        case position, points, wins
        case driver = "Driver"
        case constructors = "Constructors"
    }

    var id: String { driver.driverId }
    var teamId: String? { constructors.first?.constructorId }
    var teamName: String { constructors.first?.name ?? "—" }
}

struct Driver: Decodable {
    let driverId: String
    let permanentNumber: String?
    let code: String?
    let givenName: String
    let familyName: String

    var shortCode: String { code ?? String(familyName.prefix(3)).uppercased() }
}

struct Constructor: Decodable {
    let constructorId: String
    let name: String
}

// MARK: - Date parsing

enum ErgastDate {
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Combines Ergast "YYYY-MM-DD" + "HH:mm:ssZ" into a Date. Time defaults to midnight UTC.
    static func parse(date: String, time: String?) -> Date? {
        let t = time ?? "00:00:00Z"
        return formatter.date(from: "\(date)T\(t)")
    }
}
