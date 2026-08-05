import SwiftUI

/// Name field + minutes/seconds wheels for creating or editing a rest-timer preset.
struct TimerPresetEditorSheet: View {
    let initialName: String
    let initialSeconds: Int
    let onSave: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var minutes: Int
    @State private var seconds: Int

    init(initialName: String, initialSeconds: Int, onSave: @escaping (String, Int) -> Void) {
        self.initialName = initialName
        self.initialSeconds = initialSeconds
        self.onSave = onSave
        _name = State(initialValue: initialName)
        _minutes = State(initialValue: max(0, initialSeconds / 60))
        _seconds = State(initialValue: initialSeconds % 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Name (e.g. Heavy)", text: $name)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(ThemeTokens.backgroundCard))
                    .foregroundStyle(ThemeTokens.textPrimary)
                    .padding(.horizontal)

                HStack(spacing: 0) {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<16) { Text("\($0) min").tag($0) }
                    }
                    .pickerStyle(.wheel).frame(maxWidth: .infinity)
                    Picker("Seconds", selection: $seconds) {
                        ForEach([0, 15, 30, 45], id: \.self) { Text("\($0) sec").tag($0) }
                    }
                    .pickerStyle(.wheel).frame(maxWidth: .infinity)
                }
                .frame(maxHeight: 180)

                Spacer()
            }
            .padding(.top, 8)
            .background(ThemeTokens.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Timer Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(ThemeTokens.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, max(15, minutes * 60 + seconds))
                        dismiss()
                    }
                    .foregroundStyle(ThemeTokens.accent)
                    .disabled(minutes == 0 && seconds == 0)
                }
            }
        }
    }
}
