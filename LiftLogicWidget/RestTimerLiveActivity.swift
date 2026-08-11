import ActivityKit
import WidgetKit
import SwiftUI

// LiftLogic accent palette — duplicated here so the widget target doesn't need to share
// ThemeTokens.swift/AccentColorOption. Keep these 4 RGB values in sync with AccentColorOption's
// cases in LiftLogic/Services/ThemeTokens.swift if that palette ever changes.
private func accentColor(for rawValue: String) -> Color {
    switch rawValue {
    case "blue": return Color(red: 0.20, green: 0.55, blue: 0.95)
    case "teal": return Color(red: 0.10, green: 0.75, blue: 0.70)
    case "pink": return Color(red: 0.95, green: 0.30, blue: 0.55)
    default:     return Color(red: 1.0, green: 0.42, blue: 0.21)  // "orange" and any unknown value
    }
}

struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock Screen / Banner
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(accentColor(for: context.attributes.accentColorOption))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    timerText(context: context)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 110, alignment: .leading)
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
                        .foregroundStyle(accentColor(for: context.attributes.accentColorOption))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context: context)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.isPaused ? "Paused" : "Rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(accentColor(for: context.attributes.accentColorOption))
            } compactTrailing: {
                timerText(context: context)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .frame(maxWidth: 50)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(accentColor(for: context.attributes.accentColorOption))
            }
            .keylineTint(accentColor(for: context.attributes.accentColorOption))
        }
    }

    @ViewBuilder
    private func timerText(context: ActivityViewContext<RestTimerAttributes>) -> some View {
        if context.state.isPaused {
            Text(formatPaused(context.state.pausedRemaining))
        } else if context.state.endDate > Date() {
            Text(timerInterval: Date()...context.state.endDate, countsDown: true)
        } else {
            Text("0:00")
        }
    }

    private func formatPaused(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
