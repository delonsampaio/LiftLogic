import SwiftUI

/// Drill-down picker for AppSettings.defaultBar — pulled out of SettingsView's main list
/// (was 8 full-width rows shown inline) to match the same NavigationLink pattern already
/// used there for Plate Inventory, so picking a single default bar doesn't push every other
/// Settings section further down the page.
struct DefaultBarPickerView: View {
    let settings: AppSettings
    @State private var showCustomBarSheet = false
    @State private var customBarInput = ""
    @FocusState private var customBarFocused: Bool

    var body: some View {
        List {
            ForEach(BarType.allCases) { bar in
                HStack {
                    Text(bar == .custom
                         ? "Custom (\(String(format: "%.1f", settings.customBarWeight)) \(settings.unit.symbol))"
                         : bar.displayName)
                    Spacer()
                    if settings.defaultBar == bar {
                        Image(systemName: "checkmark")
                            .foregroundStyle(settings.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if bar == .custom {
                        customBarInput = String(settings.customBarWeight)
                        showCustomBarSheet = true
                    } else {
                        settings.defaultBar = bar
                    }
                }
            }
        }
        .navigationTitle("Default Bar")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(ThemeTokens.backgroundPrimary)
        .sheet(isPresented: $showCustomBarSheet) {
            customBarWeightSheet
        }
    }

    private var customBarInputValue: Double? {
        guard let value = Double(customBarInput), value > 0,
              value <= (settings.unit == .lbs ? 2000 : 907)
        else { return nil }
        return value
    }

    private var customBarWeightSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter Custom Bar Weight")
                    .font(.headline)
                    .foregroundStyle(ThemeTokens.textPrimary)
                HStack {
                    TextField("45", text: $customBarInput)
                        .keyboardType(.decimalPad)
                        .focused($customBarFocused)
                        .font(.largeTitle.weight(.bold))
                        .monospaced()
                        .foregroundStyle(ThemeTokens.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(settings.unit.symbol)
                        .foregroundStyle(ThemeTokens.textMuted)
                        .font(.title2)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(ThemeTokens.backgroundCard))
                .padding(.horizontal)

                if !customBarInput.isEmpty && customBarInputValue == nil {
                    Text("Enter a number between 0 and \(settings.unit == .lbs ? 2000 : 907)")
                        .font(.caption)
                        .foregroundStyle(ThemeTokens.warningAmber)
                }

                Spacer()
            }
            .padding(.top, 32)
            .background(ThemeTokens.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Custom Bar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showCustomBarSheet = false }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { customBarFocused = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let value = customBarInputValue {
                            settings.customBarWeight = value
                            settings.defaultBar = .custom
                            showCustomBarSheet = false
                        }
                    }
                    .foregroundStyle(customBarInputValue == nil ? ThemeTokens.textMuted : settings.accentColor)
                    .disabled(customBarInputValue == nil)
                }
            }
        }
    }
}
