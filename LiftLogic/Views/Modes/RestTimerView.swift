import SwiftUI

struct RestTimerView: View {
    let timer: TimerService
    let settings: AppSettings
    @Binding var isPresented: Bool

    @State private var showCustomPicker = false

    var body: some View {
        VStack(spacing: 20) {
            // Timer display
            Text(timer.state == .idle ? "Rest Timer" : timer.formattedTime)
                .font(.system(size: 48, weight: .black, design: .monospaced))
                .foregroundStyle(timer.state == .finished ? ThemeTokens.accent : ThemeTokens.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: timer.remainingSeconds)

            // Preset chips
            HStack(spacing: 8) {
                ForEach(timer.presets, id: \.self) { seconds in
                    presetChip(seconds: seconds, label: formatPreset(seconds), isCustom: false)
                }
                presetChip(
                    seconds: settings.customTimerSeconds,
                    label: settings.customTimerSeconds > 0 ? formatPreset(settings.customTimerSeconds) : "Custom",
                    isCustom: true
                )
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
        .sheet(isPresented: $showCustomPicker) {
            CustomTimerPickerSheet(
                initialSeconds: settings.customTimerSeconds > 0 ? settings.customTimerSeconds : 240
            ) { seconds in
                settings.customTimerSeconds = seconds
                timer.start(seconds: seconds)
            }
            .presentationDetents([.height(340)])
        }
    }

    @ViewBuilder
    private func presetChip(seconds: Int, label: String, isCustom: Bool) -> some View {
        let isActive = timer.state != .idle && timer.selectedPreset == seconds && seconds > 0
        Button {
            if isCustom && settings.customTimerSeconds == 0 {
                showCustomPicker = true
            } else if isCustom {
                // Long-press would edit; tap starts. Provide tap-to-start with current value.
                timer.start(seconds: settings.customTimerSeconds)
            } else {
                timer.start(seconds: seconds)
            }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? ThemeTokens.accent : ThemeTokens.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
        .if(isCustom) { view in
            view.contextMenu {
                Button("Edit duration", systemImage: "pencil") {
                    showCustomPicker = true
                }
            }
        }
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
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m):\(String(format: "%02d", s))"
    }
}

// MARK: — Custom timer picker

private struct CustomTimerPickerSheet: View {
    let initialSeconds: Int
    let onStart: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var minutes: Int
    @State private var seconds: Int

    init(initialSeconds: Int, onStart: @escaping (Int) -> Void) {
        self.initialSeconds = initialSeconds
        self.onStart = onStart
        _minutes = State(initialValue: initialSeconds / 60)
        _seconds = State(initialValue: initialSeconds % 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<16) { Text("\($0) min").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Seconds", selection: $seconds) {
                        ForEach([0, 15, 30, 45], id: \.self) { Text("\($0) sec").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: 180)

                Button {
                    let total = max(15, minutes * 60 + seconds)
                    onStart(total)
                    dismiss()
                } label: {
                    Text("Start")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(ThemeTokens.accent))
                }
                .padding(.horizontal)
                .disabled(minutes == 0 && seconds == 0)
                .opacity(minutes == 0 && seconds == 0 ? 0.5 : 1.0)
            }
            .padding(.top, 8)
            .background(ThemeTokens.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Custom Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ThemeTokens.textMuted)
                }
            }
        }
    }
}

// Small helper for conditional view modifiers
private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
