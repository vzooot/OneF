import ActivityKit
import WidgetKit
import SwiftUI

/// Wolt-style live tracking: the pinned session countdown on the Lock Screen
/// and in the Dynamic Island, flipping to LIVE at lights out.
struct RaceLiveActivity: Widget {
    private let f1Red = Color(red: 0.882, green: 0.024, blue: 0.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RaceActivityAttributes.self) { context in
            lockScreenView(context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.05, blue: 0.07))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.attributes.flag) \(context.attributes.sessionShort)")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isLive {
                        Text("LIVE")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(f1Red)
                    } else {
                        Text(timerInterval: Date.now...context.state.sessionDate, countsDown: true)
                            .font(.system(size: 15, weight: .black).monospacedDigit())
                            .foregroundStyle(f1Red)
                            .frame(maxWidth: 70)
                            .multilineTextAlignment(.trailing)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 2) {
                        Text(context.attributes.raceName.uppercased())
                            .font(.system(size: 13, weight: .black).width(.condensed).italic())
                            .foregroundStyle(.white)
                        Text(context.state.isLive
                             ? "\(context.attributes.sessionName.uppercased()) IS ON TRACK"
                             : "\(context.attributes.sessionName.uppercased()) · STARTING SOON")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                if context.state.isLive {
                    Circle()
                        .fill(f1Red)
                        .frame(width: 10, height: 10)
                } else {
                    Text("🏁")
                }
            } compactTrailing: {
                if context.state.isLive {
                    Text("LIVE")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(f1Red)
                } else {
                    Text(timerInterval: Date.now...context.state.sessionDate, countsDown: true)
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                        .foregroundStyle(f1Red)
                        .frame(maxWidth: 60)
                        .multilineTextAlignment(.trailing)
                }
            } minimal: {
                if context.state.isLive {
                    Circle()
                        .fill(f1Red)
                        .frame(width: 10, height: 10)
                } else {
                    Text("🏁")
                }
            }
            .keylineTint(f1Red)
        }
    }

    private func lockScreenView(_ context: ActivityViewContext<RaceActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(context.attributes.flag)
                    Text(context.attributes.raceName.uppercased())
                        .font(.system(size: 15, weight: .black).width(.condensed).italic())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(context.attributes.sessionName.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(f1Red)
            }

            Spacer()

            if context.state.isLive {
                HStack(spacing: 7) {
                    Circle()
                        .fill(f1Red)
                        .frame(width: 10, height: 10)
                    Text("LIVE")
                        .font(.system(size: 24, weight: .black).width(.condensed))
                        .foregroundStyle(f1Red)
                }
            } else {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(timerInterval: Date.now...context.state.sessionDate, countsDown: true)
                        .font(.system(size: 26, weight: .black).width(.condensed).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(maxWidth: 110)
                        .multilineTextAlignment(.trailing)
                    Text("TO GREEN LIGHT")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(16)
    }
}
