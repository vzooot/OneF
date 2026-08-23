import ActivityKit
import Foundation

/// Starts, refreshes, and ends the Lock Screen / Dynamic Island countdown.
@MainActor
enum LiveActivityManager {
    static var isActive: Bool {
        !Activity<RaceActivityAttributes>.activities.isEmpty
    }

    /// Pins a countdown to the given session on the Lock Screen.
    static func start(race: Race, session: WeekendSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endAll()

        let attributes = RaceActivityAttributes(
            raceName: race.raceName,
            flag: Flags.emoji(for: race.circuit.location.country),
            sessionName: session.kind.rawValue,
            sessionShort: session.kind.short
        )
        let end = session.date.addingTimeInterval(session.kind.expectedDuration)
        let state = RaceActivityAttributes.ContentState(
            sessionDate: session.date,
            sessionEndDate: end,
            isLive: session.date <= .now
        )
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: end)
            )
        } catch {
            NSLog("OneF LiveActivity request failed: %@", String(describing: error))
        }
    }

    static func endAll() {
        for activity in Activity<RaceActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// Called when the app comes to the foreground: flips a pinned countdown
    /// to LIVE once its session has started, and clears finished ones.
    static func refresh() {
        let now = Date()
        for activity in Activity<RaceActivityAttributes>.activities {
            let state = activity.content.state
            if now >= state.sessionEndDate {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            } else if now >= state.sessionDate, !state.isLive {
                var updated = state
                updated.isLive = true
                Task { await activity.update(.init(state: updated, staleDate: state.sessionEndDate)) }
            } else {
                // Touch the activity so its view re-renders — this is what
                // flips the countdown from relative style to the ticking
                // timer once the session is under 24 hours away.
                Task { await activity.update(.init(state: state, staleDate: state.sessionEndDate)) }
            }
        }
    }
}
