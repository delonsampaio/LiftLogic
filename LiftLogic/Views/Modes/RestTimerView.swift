import SwiftUI

struct RestTimerView: View {
    let timer: TimerService
    let settings: AppSettings
    @Binding var isPresented: Bool

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.4 : 1.0 }

    var body: some View {
        VStack(spacing: 20) {
            // Timer display
            Text(timer.state == .idle ? "Rest Timer" : timer.formattedTime)
                .font(.system(size: 48 * scale, weight: .black, design: .monospaced))
                .foregroundStyle(timer.state == .finished ? ThemeTokens.accent : ThemeTokens.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: timer.remainingSeconds)

            // Preset chips — built-ins first, then the user's named presets.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(timer.presets, id: \.self) { seconds in
                        presetChip(seconds: seconds, label: formatPreset(seconds), name: nil)
                    }
                    ForEach(settings.restTimerPresets) { preset in
                        presetChip(seconds: preset.seconds, label: preset.name, name: preset.name)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

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
    private func presetChip(seconds: Int, label: String, name: String?) -> some View {
        let isActive = timer.state != .idle && timer.selectedPreset == seconds && seconds > 0
        Button {
            timer.start(seconds: seconds)
        } label: {
            Text(label)
                .font(sizeClass == .regular ? .subheadline.weight(.semibold) : .footnote.weight(.semibold))
                .foregroundStyle(isActive ? ThemeTokens.accent : ThemeTokens.textMuted)
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 8 * scale)
                .background(
                    Capsule()
                        .fill(isActive ? ThemeTokens.accent.opacity(0.15) : Color(white: 0.12))
                        .overlay(Capsule().strokeBorder(
                            isActive ? ThemeTokens.accent.opacity(0.4) : Color(white: 0.2),
                            lineWidth: 1
                        ))
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func controlButton(systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(sizeClass == .regular ? .largeTitle : .title2)
            .foregroundStyle(color)
            .frame(width: 52 * scale, height: 52 * scale)
            .background(Circle().fill(Color(white: 0.15)))
    }

    private func formatPreset(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m):\(String(format: "%02d", s))"
    }
}
