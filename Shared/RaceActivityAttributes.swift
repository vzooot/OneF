import ActivityKit
import Foundation

/// Live Activity payload, compiled into both the app (which starts and
/// updates the activity) and the widget extension (which renders it).
struct RaceActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Session start — the countdown target.
        var sessionDate: Date
        /// Expected session end, used for the "ends in" timer while live.
        var sessionEndDate: Date
        var isLive: Bool
    }

    var raceName: String
    var flag: String
    var sessionName: String
    var sessionShort: String
}
