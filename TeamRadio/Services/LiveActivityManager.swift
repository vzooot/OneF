import ActivityKit
import Foundation

/// Starts, refreshes, and ends the Lock Screen / Dynamic Island countdown.
@MainActor
enum LiveActivityManager {
    // iOS force-ends every Live Activity after ~8 hours, so a pin on a session
    // days away can't survive on its own. The pin is therefore stored as an
    // intent, and rearmIfNeeded() silently restarts the activity whenever the
    // app comes to the foreground.
    private static let pinKindKey = "pinnedSessionKind"
    private static let pinDateKey = "pinnedSessionDate"

    static var isActive: Bool {
        !Activity<RaceActivityAttributes>.activities.isEmpty
    }

    /// The user's pin choice — outlives the activity the system ends.
    static var hasPinIntent: Bool {
        UserDefaults.standard.object(forKey: pinDateKey) != nil
    }

    /// Pins a countdown to the given session on the Lock Screen.
    static func start(race: Race, session: WeekendSession) {
        UserDefaults.standard.set(session.kind.rawValue, forKey: pinKindKey)
        UserDefaults.standard.set(session.date.timeIntervalSince1970, forKey: pinDateKey)
        startActivity(race: race, session: session)
    }

    /// User-initiated unpin: forget the intent and tear the activity down.
    static func unpin() {
        clearPinIntent()
        endAll()
    }

    private static func clearPinIntent() {
        UserDefaults.standard.removeObject(forKey: pinKindKey)
        UserDefaults.standard.removeObject(forKey: pinDateKey)
    }

    private static func startActivity(race: Race, session: WeekendSession) {
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
            NSLog("TeamRadio LiveActivity request failed: %@", String(describing: error))
        }
    }

    static func endAll() {
        for activity in Activity<RaceActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// Called when the app comes to the foreground: flips a pinned countdown
    /// to LIVE once its session has started, clears finished ones, and
    /// restarts a pinned countdown the system ended.
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
        Task { await rearmIfNeeded() }
    }

    /// Re-pins the remembered session after iOS's ~8-hour Live Activity limit
    /// killed the previous one. No-op while an activity is still alive.
    private static func rearmIfNeeded() async {
        guard let kindRaw = UserDefaults.standard.string(forKey: pinKindKey),
              UserDefaults.standard.object(forKey: pinDateKey) != nil,
              let kind = WeekendSession.Kind(rawValue: kindRaw) else { return }
        let date = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: pinDateKey))

        // The pinned session is over — the pin has served its purpose.
        if Date() >= date.addingTimeInterval(kind.expectedDuration) {
            clearPinIntent()
            return
        }
        guard !isActive else { return }
        guard let race = try? await F1API.nextRace(),
              let session = race.sessions.first(where: {
                  $0.kind == kind && abs($0.date.timeIntervalSince(date)) < 60
              }) else { return }
        startActivity(race: race, session: session)
    }
}
