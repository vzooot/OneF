import SwiftUI

/// Horizontal strip of every round in the season, auto-scrolled to the next one.
struct SeasonView: View {
    let season: [Race]
    let nextRaceId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("SEASON \(season.first?.season ?? "")")

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(season) { race in
                            RoundCard(race: race, isNext: race.id == nextRaceId)
                                .id(race.id)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                .onAppear {
                    if let nextRaceId {
                        proxy.scrollTo(nextRaceId, anchor: .center)
                    }
                }
            }
        }
    }
}

struct RoundCard: View {
    let race: Race
    let isNext: Bool

    private var isPast: Bool {
        guard let start = race.startDate else { return false }
        return start <= .now && !isNext
    }

    var body: some View {
        VStack(spacing: 5) {
            Text(Flags.emoji(for: race.circuit.location.country))
                .font(.system(size: 26))
                .saturation(isPast ? 0.2 : 1)

            Text("R\(race.roundNumber)")
                .font(.f1(13).italic())
                .foregroundStyle(isNext ? Theme.f1Red : Theme.dimText)

            Text(race.circuit.location.locality.uppercased())
                .font(.f1(12, weight: .bold))
                .foregroundStyle(isPast ? Theme.faintText : .white)
                .lineLimit(1)

            if isPast {
                Text("🏁")
                    .font(.system(size: 10))
            } else if let start = race.startDate {
                Text(start.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isNext ? Theme.f1Red : Theme.dimText)
            }
        }
        .frame(width: 92)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isNext ? Theme.f1Red.opacity(0.12) : Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isNext ? Theme.f1Red : Theme.cardStroke, lineWidth: isNext ? 1.5 : 1)
                )
        )
        .opacity(isPast ? 0.6 : 1)
    }
}
