import Foundation

/// Circuit geometry and metadata from the MultiViewer circuits API.
/// Coordinates are the track centerline in decimeters.
struct TrackMap: Decodable {
    struct Corner: Decodable {
        let number: Int
        let trackPosition: Position
    }

    struct Position: Decodable {
        let x: Double
        let y: Double
    }

    struct PitLoss: Decodable {
        let normal: String?
        let sc: String?
        let vsc: String?
    }

    let x: [Double]
    let y: [Double]
    let corners: [Corner]
    let rotation: Double?
    let pitLoss: PitLoss?
    let circuitName: String?
    let year: Int?

    /// Track length computed from the centerline polyline (decimeters → km).
    var lengthKm: Double {
        guard x.count > 2, x.count == y.count else { return 0 }
        var total = 0.0
        for i in 0..<x.count {
            let j = (i + 1) % x.count
            total += hypot(x[j] - x[i], y[j] - y[i])
        }
        return total / 10_000
    }

    /// Direction of travel, from the signed area of the centerline polygon.
    var isClockwise: Bool {
        guard x.count > 2, x.count == y.count else { return true }
        var area = 0.0
        for i in 0..<x.count {
            let j = (i + 1) % x.count
            area += x[i] * y[j] - x[j] * y[i]
        }
        return area < 0
    }

    /// Pit lane time loss in seconds under normal racing conditions.
    var pitLossSeconds: Double? {
        guard let s = pitLoss?.normal else { return nil }
        return Double(s)
    }
}
