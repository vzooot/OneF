import SwiftUI

/// Circuit section: the interactive 3D track map plus key stats derived from
/// the real track geometry.
struct TrackSectionView: View {
    let map: TrackMap
    let circuit: Circuit

    @State private var resetToken = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("THE CIRCUIT")

            VStack(spacing: 0) {
                Track3DView(map: map, resetToken: resetToken)
                    .frame(height: 300)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            resetToken += 1
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.dimText)
                                .padding(9)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .overlay(Circle().strokeBorder(Theme.cardStroke, lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                    }

                Text("DRAG TO ROTATE · PINCH TO ZOOM")
                    .font(.f1(10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Theme.faintText)
                    .padding(.bottom, 12)

                HStack(spacing: 8) {
                    statChip(String(format: "%.2f KM", map.lengthKm), "LENGTH")
                    statChip("\(map.corners.count)", "CORNERS")
                    statChip(map.isClockwise ? "CW ↻" : "ACW ↺", "DIRECTION")
                    if let pitLoss = map.pitLossSeconds {
                        statChip(String(format: "%.0fS", pitLoss), "PIT LOSS")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Theme.card, Color.black.opacity(0.7)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.cardStroke, lineWidth: 1)
                    )
            )

            if let wiki = URL(string: circuit.url ?? "") {
                Link(destination: wiki) {
                    HStack(spacing: 4) {
                        Text("Circuit details on Wikipedia")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.dimText)
                }
                .padding(.leading, 4)
            }
        }
    }

    private func statChip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.f1Digits(17))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.f1(10, weight: .bold))
                .tracking(1)
                .foregroundStyle(Theme.dimText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.cardStroke, lineWidth: 1)
                )
        )
    }
}
