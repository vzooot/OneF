import SwiftUI

struct ContentView: View {
    @State private var model = RaceViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.f1Red.opacity(0.18), .clear],
                center: .top, startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea()

            switch model.phase {
            case .loading:
                LoadingView()
            case .failed(let message):
                ErrorView(message: message) {
                    Task { await model.load() }
                }
            case .loaded:
                loadedContent
            }
        }
        .task { await model.load() }
    }

    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView()

                if let race = model.nextRace {
                    RaceHeroView(race: race)

                    if let start = race.startDate {
                        CountdownView(target: start)
                    }

                    WeekendScheduleView(race: race)
                } else {
                    SeasonOverBanner()
                }

                if !model.standings.isEmpty {
                    StandingsView(standings: model.standings)
                }

                if !model.season.isEmpty {
                    SeasonView(season: model.season, nextRaceId: model.nextRace?.id)
                }

                FooterView()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .refreshable { await model.load() }
    }
}

// MARK: - Header

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                SpeedLines()
                    .fill(Theme.f1Red)
                    .frame(width: 46, height: 22)

                HStack(spacing: 0) {
                    Text("ONE")
                        .foregroundStyle(.white)
                    Text("F")
                        .foregroundStyle(Theme.f1Red)
                }
                .font(.f1(40).italic())
            }
            Text("NEXT RACE COUNTDOWN")
                .font(.f1(13, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Theme.dimText)
                .padding(.leading, 56)
        }
        .padding(.top, 4)
    }
}

/// The three trailing speed strokes from the F1 wordmark, drawn as skewed bars.
struct SpeedLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let bar = rect.width / 5.5
        let skew = rect.height * 0.55
        for i in 0..<3 {
            let x = CGFloat(i) * bar * 1.8
            path.move(to: CGPoint(x: x + skew, y: 0))
            path.addLine(to: CGPoint(x: x + skew + bar, y: 0))
            path.addLine(to: CGPoint(x: x + bar, y: rect.height))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Loading / error / empty states

struct LoadingView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            Text("🏁")
                .font(.system(size: 44))
                .scaleEffect(pulse ? 1.15 : 0.9)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)
            Text("WARMING UP TYRES…")
                .font(.f1(15).italic())
                .tracking(3)
                .foregroundStyle(Theme.dimText)
        }
        .onAppear { pulse = true }
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("🔴 RED FLAG")
                .font(.f1(24).italic())
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.dimText)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text("RESTART RACE")
                    .font(.f1(15).italic())
                    .tracking(2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.f1Red, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(32)
    }
}

struct SeasonOverBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🏆 SEASON COMPLETE")
                .font(.f1(24).italic())
                .foregroundStyle(.white)
            Text("No more races on the current calendar. See you next season!")
                .font(.subheadline)
                .foregroundStyle(Theme.dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct FooterView: View {
    var body: some View {
        Text("Data: Jolpica F1 API · Unofficial app, not associated with Formula 1")
            .font(.caption2)
            .foregroundStyle(Theme.faintText)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

#Preview {
    ContentView()
}
