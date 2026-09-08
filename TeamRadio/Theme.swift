import SwiftUI

/// Visual language of the app: F1-broadcast dark palette, condensed italic type.
enum Theme {
    static let f1Red = Color(red: 0.882, green: 0.024, blue: 0.0)          // #E10600
    static let background = Color(red: 0.043, green: 0.043, blue: 0.059)   // #0B0B0F
    static let card = Color(red: 0.086, green: 0.086, blue: 0.11)          // #16161C
    static let cardStroke = Color.white.opacity(0.08)
    static let dimText = Color.white.opacity(0.55)
    static let faintText = Color.white.opacity(0.35)

    /// Team colors keyed by Ergast constructorId.
    static let teamColors: [String: Color] = [
        "red_bull": Color(red: 0.14, green: 0.12, blue: 0.60),
        "ferrari": Color(red: 0.91, green: 0.05, blue: 0.05),
        "mercedes": Color(red: 0.0, green: 0.82, blue: 0.75),
        "mclaren": Color(red: 1.0, green: 0.53, blue: 0.0),
        "aston_martin": Color(red: 0.0, green: 0.44, blue: 0.37),
        "alpine": Color(red: 0.0, green: 0.57, blue: 1.0),
        "williams": Color(red: 0.0, green: 0.35, blue: 0.75),
        "rb": Color(red: 0.42, green: 0.57, blue: 1.0),
        "racing_bulls": Color(red: 0.42, green: 0.57, blue: 1.0),
        "sauber": Color(red: 0.0, green: 0.89, blue: 0.3),
        "audi": Color(red: 0.6, green: 0.9, blue: 0.2),
        "haas": Color(red: 0.7, green: 0.7, blue: 0.7),
        "cadillac": Color(red: 0.85, green: 0.75, blue: 0.4),
    ]

    static func teamColor(_ constructorId: String?) -> Color {
        guard let id = constructorId else { return .gray }
        return teamColors[id] ?? .gray
    }
}

extension Font {
    /// The F1-broadcast look: black weight, condensed. Apply .italic() at the call site when wanted.
    static func f1(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .default).width(.condensed)
    }

    static func f1Digits(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default).width(.condensed).monospacedDigit()
    }
}

/// Country name (as Ergast reports it) → flag emoji.
enum Flags {
    private static let map: [String: String] = [
        "Australia": "🇦🇺", "China": "🇨🇳", "Japan": "🇯🇵", "Bahrain": "🇧🇭",
        "Saudi Arabia": "🇸🇦", "USA": "🇺🇸", "United States": "🇺🇸", "Italy": "🇮🇹",
        "Monaco": "🇲🇨", "Canada": "🇨🇦", "Spain": "🇪🇸", "Austria": "🇦🇹",
        "UK": "🇬🇧", "United Kingdom": "🇬🇧", "Great Britain": "🇬🇧",
        "Hungary": "🇭🇺", "Belgium": "🇧🇪", "Netherlands": "🇳🇱",
        "Azerbaijan": "🇦🇿", "Singapore": "🇸🇬", "Mexico": "🇲🇽",
        "Brazil": "🇧🇷", "Qatar": "🇶🇦", "UAE": "🇦🇪", "United Arab Emirates": "🇦🇪",
        "France": "🇫🇷", "Germany": "🇩🇪", "Portugal": "🇵🇹", "Vietnam": "🇻🇳",
        "South Africa": "🇿🇦", "Korea": "🇰🇷", "India": "🇮🇳", "Turkey": "🇹🇷",
        "Russia": "🇷🇺", "Argentina": "🇦🇷", "Malaysia": "🇲🇾", "Thailand": "🇹🇭",
        "Rwanda": "🇷🇼",
    ]

    static func emoji(for country: String?) -> String {
        guard let country else { return "🏁" }
        return map[country] ?? "🏁"
    }
}
