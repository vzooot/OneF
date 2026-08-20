import Foundation

/// Thin async client for the Jolpica F1 API (the community successor to Ergast).
/// Docs: https://github.com/jolpica/jolpica-f1
enum F1API {
    static let base = URL(string: "https://api.jolpi.ca/ergast/f1")!

    enum APIError: LocalizedError {
        case badResponse(Int)

        var errorDescription: String? {
            switch self {
            case .badResponse(let code): "The F1 API answered with status \(code)."
            }
        }
    }

    private static func fetch(_ path: String, query: [URLQueryItem] = []) async throws -> MRData {
        var components = URLComponents(url: base.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.badResponse(http.statusCode)
        }
        return try JSONDecoder().decode(ErgastResponse.self, from: data).mrData
    }

    /// The next grand prix on the calendar, with full weekend session times.
    static func nextRace() async throws -> Race? {
        try await fetch("current/next.json").raceTable?.races.first
    }

    /// The full current-season calendar.
    static func season() async throws -> [Race] {
        try await fetch("current.json", query: [URLQueryItem(name: "limit", value: "30")])
            .raceTable?.races ?? []
    }

    /// Current championship top order.
    static func driverStandings(limit: Int = 5) async throws -> [DriverStanding] {
        try await fetch("current/driverstandings.json", query: [URLQueryItem(name: "limit", value: "\(limit)")])
            .standingsTable?.standingsLists.first?.driverStandings ?? []
    }
}
