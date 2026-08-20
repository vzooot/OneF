import SwiftUI

/// Full race-weekend timetable in the viewer's local timezone.
struct WeekendScheduleView: View {
    let race: Race

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("RACE WEEKEND")

            VStack(spacing: 0) {
                let sessions = race.sessions
                let nextId = sessions.first(where: { $0.date > .now })?.id

                ForEach(sessions) { session in
                    SessionRow(
                        session: session,
                        isPast: session.date <= .now,
                        isNext: session.id == nextId
                    )
                    if session.id != sessions.last?.id {
                        Divider().overlay(Color.white.opacity(0.06))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Theme.cardStroke, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text("All times local · \(TimeZone.current.identifier)")
                .font(.caption2)
                .foregroundStyle(Theme.faintText)
                .padding(.leading, 4)
        }
    }
}

struct SessionRow: View {
    let session: WeekendSession
    let isPast: Bool
    let isNext: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(session.kind.short)
                .font(.f1(13).italic())
                .foregroundStyle(session.kind == .race ? .white : Theme.dimText)
                .frame(width: 46, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(session.kind == .race ? Theme.f1Red : Color.white.opacity(0.06))
                )

            Text(session.kind.rawValue.uppercased())
                .font(.f1(15, weight: .bold))
                .foregroundStyle(isPast ? Theme.faintText : .white)
                .strikethrough(isPast, color: Theme.faintText)

            if isNext {
                Text("NEXT")
                    .font(.f1(10, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(Theme.f1Red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Theme.f1Red.opacity(0.6), lineWidth: 1)
                    )
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(session.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isPast ? Theme.faintText : Theme.dimText)
                Text(session.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 15, weight: .bold).monospacedDigit())
                    .foregroundStyle(isPast ? Theme.faintText : .white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(isNext ? Theme.f1Red.opacity(0.08) : .clear)
        .overlay(alignment: .leading) {
            if isNext {
                Rectangle()
                    .fill(Theme.f1Red)
                    .frame(width: 3)
            }
        }
    }
}

/// Shared section heading with a red slash accent.
struct SectionTitle: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Theme.f1Red)
                .frame(width: 4, height: 18)
                .rotationEffect(.degrees(12))
            Text(text)
                .font(.f1(19).italic())
                .foregroundStyle(.white)
        }
    }
}
