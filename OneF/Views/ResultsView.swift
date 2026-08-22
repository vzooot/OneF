import SwiftUI

/// Results tab: podium and full classification of the last grand prix,
/// switchable to qualifying, plus the constructors' championship.
struct ResultsView: View {
    enum Mode: String, CaseIterable {
        case race = "RACE"
        case qualifying = "QUALIFYING"
    }

    @State private var model = ResultsViewModel()
    @State private var mode: Mode = .race

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.f1Red.opacity(0.14), .clear],
                center: .top, startRadius: 0, endRadius: 380
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
                if let race = model.raceWithResults, let results = race.results, !results.isEmpty {
                    header(race: race)

                    if model.completedRaces.count > 1 {
                        roundPicker
                    }

                    Group {
                        PodiumView(results: results)

                        modePicker

                        if mode == .race {
                            if let fastest = results.first(where: { $0.hasFastestLap }) {
                                FastestLapCard(result: fastest)
                            }
                            RaceClassificationView(results: results)
                        } else if let quali = model.raceWithQualifying?.qualifyingResults, !quali.isEmpty {
                            QualifyingClassificationView(results: quali)
                        } else {
                            Text("No qualifying data yet.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.dimText)
                        }
                    }
                    .opacity(model.isSwitching ? 0.35 : 1)
                    .overlay {
                        if model.isSwitching {
                            ProgressView().tint(Theme.f1Red)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: model.isSwitching)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🏁 NO RESULTS YET")
                            .font(.f1(24).italic())
                            .foregroundStyle(.white)
                        Text("The season hasn't produced a classified race yet. Check back after lights out.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.dimText)
                    }
                    .padding(.top, 8)
                }

                if !model.constructorStandings.isEmpty {
                    ConstructorStandingsView(standings: model.constructorStandings)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .refreshable { await model.load() }
    }

    private func header(race: Race) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RESULTS")
                .font(.f1(30).italic())
                .foregroundStyle(.white)
            Text("\(Flags.emoji(for: race.circuit.location.country)) \(race.raceName.uppercased()) · ROUND \(race.roundNumber)")
                .font(.f1(12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dimText)
        }
        .padding(.top, 8)
    }

    /// Horizontal strip of every completed round; tap to load its results.
    private var roundPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.completedRaces) { race in
                        let isSelected = race.round == model.selectedRound
                        Button {
                            Task { await model.select(round: race.round) }
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(Flags.emoji(for: race.circuit.location.country)) R\(race.roundNumber)")
                                    .font(.f1(13).italic())
                                    .foregroundStyle(isSelected ? Theme.f1Red : .white)
                                Text(race.circuit.location.locality.uppercased())
                                    .font(.f1(10, weight: .bold))
                                    .foregroundStyle(isSelected ? .white : Theme.dimText)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Theme.f1Red.opacity(0.15) : Theme.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(isSelected ? Theme.f1Red : Theme.cardStroke, lineWidth: isSelected ? 1.5 : 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .id(race.round)
                    }
                }
                .padding(.vertical, 2)
            }
            .onAppear {
                if let selected = model.selectedRound {
                    proxy.scrollTo(selected, anchor: .trailing)
                }
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(Mode.allCases, id: \.self) { candidate in
                let isSelected = candidate == mode
                Button {
                    mode = candidate
                } label: {
                    Text(candidate.rawValue)
                        .font(.f1(14).italic())
                        .tracking(1)
                        .foregroundStyle(isSelected ? .white : Theme.dimText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Theme.f1Red : Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Podium

struct PodiumView: View {
    let results: [RaceResult]

    private func result(_ position: String) -> RaceResult? {
        results.first { $0.position == position }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if let p2 = result("2") { step(p2, height: 74) }
            if let p1 = result("1") { step(p1, height: 104) }
            if let p3 = result("3") { step(p3, height: 56) }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Theme.card, Theme.f1Red.opacity(0.16)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.cardStroke, lineWidth: 1)
                )
        )
    }

    private func step(_ result: RaceResult, height: CGFloat) -> some View {
        VStack(spacing: 6) {
            if result.position == "1" {
                Text("🏆")
                    .font(.system(size: 26))
            }
            Text(result.driver.shortCode)
                .font(.f1(24).italic())
                .foregroundStyle(.white)
            Text(result.constructor.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.dimText)
                .lineLimit(1)

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Theme.cardStroke, lineWidth: 1)
                    )
                Rectangle()
                    .fill(Theme.teamColor(result.constructor.constructorId))
                    .frame(height: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                Text(result.position)
                    .font(.f1Digits(34))
                    .foregroundStyle(result.position == "1" ? Theme.f1Red : .white)
                    .padding(.top, 14)
            }
            .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Race classification

struct FastestLapCard: View {
    let result: RaceResult

    private let purple = Color(red: 0.63, green: 0.24, blue: 0.85)

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "stopwatch.fill")
                .foregroundStyle(purple)
            Text("FASTEST LAP")
                .font(.f1(13).italic())
                .tracking(1)
                .foregroundStyle(purple)
            Text(result.driver.shortCode)
                .font(.f1(15).italic())
                .foregroundStyle(.white)
            Spacer()
            Text(result.fastestLap?.time?.time ?? "—")
                .font(.f1Digits(16))
                .foregroundStyle(purple)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(purple.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(purple.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

struct RaceClassificationView: View {
    let results: [RaceResult]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(results) { result in
                RaceResultRow(result: result)
                if result.id != results.last?.id {
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
    }
}

struct RaceResultRow: View {
    let result: RaceResult

    var body: some View {
        HStack(spacing: 10) {
            Text(result.positionText)
                .font(.f1Digits(17))
                .foregroundStyle(result.position == "1" ? Theme.f1Red : (result.finished ? .white : Theme.faintText))
                .frame(width: 28, alignment: .center)

            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.teamColor(result.constructor.constructorId))
                .frame(width: 4, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(result.driver.shortCode)
                        .font(.f1(15).italic())
                        .foregroundStyle(result.finished ? .white : Theme.dimText)
                    if result.hasFastestLap {
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(red: 0.63, green: 0.24, blue: 0.85))
                    }
                    gridDeltaBadge
                }
                Text(result.constructor.name)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.faintText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(result.gapText)
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundStyle(result.finished ? .white : Theme.f1Red.opacity(0.85))
                    .lineLimit(1)
                if let pts = Double(result.points), pts > 0 {
                    Text("+\(result.points) PTS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.dimText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var gridDeltaBadge: some View {
        if let delta = result.gridDelta, delta != 0 {
            HStack(spacing: 1) {
                Image(systemName: delta > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 7))
                Text("\(abs(delta))")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
            }
            .foregroundStyle(delta > 0 ? Color.green : Color(red: 1.0, green: 0.4, blue: 0.35))
        }
    }
}

// MARK: - Qualifying classification

struct QualifyingClassificationView: View {
    let results: [QualifyingResult]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(results) { result in
                QualifyingResultRow(result: result)
                if result.id != results.last?.id {
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
    }
}

struct QualifyingResultRow: View {
    let result: QualifyingResult

    var body: some View {
        HStack(spacing: 10) {
            Text(result.position)
                .font(.f1Digits(17))
                .foregroundStyle(result.position == "1" ? Theme.f1Red : .white)
                .frame(width: 28, alignment: .center)

            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.teamColor(result.constructor.constructorId))
                .frame(width: 4, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(result.driver.shortCode)
                    .font(.f1(15).italic())
                    .foregroundStyle(.white)
                Text(result.constructor.name)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.faintText)
            }

            Spacer()

            if let best = result.bestTime {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(best.time)
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundStyle(result.position == "1" ? Theme.f1Red : .white)
                    Text(best.segment)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.dimText)
                }
            } else {
                Text("NO TIME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.faintText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Constructors

struct ConstructorStandingsView: View {
    let standings: [ConstructorStanding]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("CONSTRUCTORS' CHAMPIONSHIP")

            VStack(spacing: 0) {
                ForEach(standings) { entry in
                    HStack(spacing: 12) {
                        Text(entry.position)
                            .font(.f1Digits(18))
                            .foregroundStyle(entry.position == "1" ? Theme.f1Red : .white)
                            .frame(width: 28, alignment: .center)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.teamColor(entry.constructor.constructorId))
                            .frame(width: 4, height: 26)

                        Text(entry.constructor.name)
                            .font(.f1(16).italic())
                            .foregroundStyle(.white)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(entry.points) PTS")
                                .font(.f1Digits(15))
                                .foregroundStyle(entry.position == "1" ? Theme.f1Red : .white)
                            if let wins = Int(entry.wins), wins > 0 {
                                Text("\(wins) \(wins == 1 ? "WIN" : "WINS")")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Theme.faintText)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)

                    if entry.id != standings.last?.id {
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
        }
    }
}
