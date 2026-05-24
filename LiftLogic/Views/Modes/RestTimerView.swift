import SwiftUI

struct RestTimerView: View {
    @Binding var isPresented: Bool
    @State private var timer = TimerService()

    var body: some View {
        VStack(spacing: 20) {
            // Timer display
            Text(timer.state == .idle ? "Rest Timer" : timer.formattedTime)
                .font(.system(size: 48, weight: .black, design: .monospaced))
                .foregroundStyle(timer.state == .finished ? ThemeTokens.accent : ThemeTokens.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: timer.remainingSeconds)

            // Preset chips
            HStack(spacing: 10) {
                ForEach(timer.presets, id: \.self) { seconds in
                    Button {
                        timer.start(seconds: seconds)
                    } label: {
                        Text(formatPreset(seconds))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(timer.selectedPreset == seconds && timer.state != .idle
                                             ? ThemeTokens.accent : ThemeTokens.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(timer.selectedPreset == seconds && timer.state != .idle
                                          ? ThemeTokens.accent.opacity(0.15) : Color(white: 0.12))
                                    .overlay(Capsule().strokeBorder(
                                        timer.selectedPreset == seconds && timer.state != .idle
                                            ? ThemeTokens.accent.opacity(0.4) : Color(white: 0.2),
                                        lineWidth: 1
                                    ))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Controls
            HStack(spacing: 16) {
                if timer.state == .running {
                    Button {
                        timer.pause()
                    } label: {
                        controlButton(systemImage: "pause.fill", color: ThemeTokens.textSecondary)
                    }
                } else if timer.state == .paused {
                    Button {
                        timer.resume()
                    } label: {
                        controlButton(systemImage: "play.fill", color: ThemeTokens.accent)
                    }
                }

                if timer.state != .idle {
                    Button {
                        timer.stop()
                    } label: {
                        controlButton(systemImage: "stop.fill", color: ThemeTokens.textMuted)
                    }
                }
            }

            Button("Dismiss") { isPresented = false }
                .font(.footnote)
                .foregroundStyle(ThemeTokens.textMuted)
        }
        .padding()
        .background(ThemeTokens.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    @ViewBuilder
    private func controlButton(systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 22))
            .foregroundStyle(color)
            .frame(width: 52, height: 52)
            .background(Circle().fill(Color(white: 0.15)))
    }

    private func formatPreset(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : "\(seconds/60)m"
    }
}
