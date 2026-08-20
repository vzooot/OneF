import SwiftUI

/// Live tick-by-tick countdown to lights out, with an F1 start gantry on top.
struct CountdownView: View {
    let target: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, target.timeIntervalSince(context.date))
            let parts = split(remaining)

            VStack(spacing: 16) {
                StartLightsView(secondsRemaining: remaining)

                if remaining <= 0 {
                    Text("IT'S LIGHTS OUT AND AWAY WE GO!")
                        .font(.f1(22).italic())
                        .foregroundStyle(Theme.f1Red)
                        .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 10) {
                        tile(parts.days, "DAYS")
                        tile(parts.hours, "HRS")
                        tile(parts.minutes, "MIN")
                        tile(parts.seconds, "SEC", hot: true)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.cardStroke, lineWidth: 1)
                    )
                    .shadow(color: Theme.f1Red.opacity(0.25), radius: 24, y: 6)
            )
        }
    }

    private func tile(_ value: Int, _ label: String, hot: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.f1Digits(42))
                .foregroundStyle(hot ? Theme.f1Red : .white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy(duration: 0.3), value: value)
            Text(label)
                .font(.f1(11, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.dimText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(hot ? Theme.f1Red.opacity(0.5) : Theme.cardStroke, lineWidth: 1)
                )
        )
    }

    private func split(_ interval: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let total = Int(interval)
        return (total / 86400, (total % 86400) / 3600, (total % 3600) / 60, total % 60)
    }
}

/// The five-light start gantry. Lights come on as race week progresses:
/// all five burn during the final 24 hours before lights out.
struct StartLightsView: View {
    let secondsRemaining: TimeInterval

    private var litCount: Int {
        let days = secondsRemaining / 86400
        if secondsRemaining <= 0 { return 0 }        // lights out — away we go
        if days >= 6 { return 0 }
        return min(5, Int((6 - days) / 6 * 5) + 1)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                ForEach(0..<5, id: \.self) { index in
                    lightColumn(on: index < litCount)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )

            if secondsRemaining > 0 && secondsRemaining < 6 * 86400 {
                Text(secondsRemaining < 86400 ? "FINAL 24 HOURS" : "IT'S RACE WEEK")
                    .font(.f1(11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Theme.f1Red)
            }
        }
    }

    private func lightColumn(on: Bool) -> some View {
        VStack(spacing: 5) {
            ForEach(0..<2, id: \.self) { _ in
                Circle()
                    .fill(on ? Theme.f1Red : Color.white.opacity(0.07))
                    .frame(width: 16, height: 16)
                    .shadow(color: on ? Theme.f1Red.opacity(0.8) : .clear, radius: 6)
            }
        }
    }
}
