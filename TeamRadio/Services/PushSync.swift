import ActivityKit
import Foundation

/// Registers this device for server-started Lock Screen countdowns: ActivityKit
/// hands out a "push-to-start" token, and the Team Radio worker uses it to
/// start the session Live Activity ~15 minutes before lights out — app closed
/// or not.
enum PushSync {
    /// The Cloudflare worker's register endpoint.
    private static let endpoint = URL(string: "https://teamradio-push.eam-adio.workers.dev/register")!

    private static var started = false

    static func start() {
        guard !started else { return }
        started = true
        Task.detached(priority: .background) {
            guard #available(iOS 17.2, *) else { return }
            for await tokenData in Activity<RaceActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                await upload(token)
            }
        }
    }

    private static func upload(_ token: String) async {
        // Debug builds get sandbox APNs tokens; TestFlight/App Store get
        // production ones. The worker needs to know which gate to knock on.
        #if DEBUG
        let env = "sandbox"
        #else
        let env = "production"
        #endif
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["token": token, "env": env])
        _ = try? await URLSession.shared.data(for: request)
    }
}
