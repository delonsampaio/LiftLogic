import ActivityKit
import WidgetKit
import SwiftUI

// LiftLogic accent — duplicated here so the widget target doesn't need to share ThemeTokens.
private let accentOrange = Color(red: 1.0, green: 0.42, blue: 0.21)

struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock Screen / Banner
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(accentOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    timerText(context: context)
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.6))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(accentOrange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context: context)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.isPaused ? "Paused" : "Rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(accentOrange)
            } compactTrailing: {
                timerText(context: context)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .frame(maxWidth: 50)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(accentOrange)
            }
            .keylineTint(accentOrange)
        }
    }

    @ViewBuilder
    private func timerText(context: ActivityViewContext<RestTimerAttributes>) -> some View {
        if context.state.isPaused {
            Text(formatPaused(context.state.pausedRemaining))
        } else {
            Text(timerInterval: Date()...context.state.endDate, countsDown: true)
        }
    }

    private func formatPaused(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
