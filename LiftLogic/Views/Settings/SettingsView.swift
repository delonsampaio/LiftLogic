import SwiftUI

struct SettingsView: View {
    let settings: AppSettings
    let vm: CalculatorViewModel
    @State private var showCustomBarSheet = false
    @State private var customBarInput = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Unit
                Section("Units") {
                    Picker("Weight Unit", selection: Binding(
                        get: { settings.unit },
                        set: { settings.unit = $0 }
                    )) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.symbol.uppercased()).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Bar
                Section("Default Bar") {
                    ForEach(BarType.allCases) { bar in
                        HStack {
                            Text(bar == .custom
                                 ? "Custom (\(String(format: "%.1f", settings.customBarWeight)) \(settings.unit.symbol))"
                                 : bar.displayName)
                            Spacer()
                            if settings.defaultBar == bar {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(ThemeTokens.accent)
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

                // Plate inventory
                Section("Plate Inventory") {
                    NavigationLink("Pounds (lbs)") {
                        PlateInventoryView(
                            inventory: Binding(
                                get: { settings.lbsInventory },
                                set: { settings.lbsInventory = $0 }
                            ),
                            unit: .lbs,
                            isPro: settings.isPro
                        )
                    }
                    NavigationLink("Kilograms (kg)") {
                        PlateInventoryView(
                            inventory: Binding(
                                get: { settings.kgInventory },
                                set: { settings.kgInventory = $0 }
                            ),
                            unit: .kg,
                            isPro: settings.isPro
                        )
                    }
                }

                if settings.isPro {
                    Section("Pro — Bodyweight") {
                        HStack {
                            Text("Bodyweight")
                            Spacer()
                            TextField("0", value: Binding(
                                get: { settings.bodyWeight },
                                set: { settings.bodyWeight = $0 }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            Text(settings.unit.symbol)
                                .foregroundStyle(ThemeTokens.textMuted)
                        }
                    }
                }

                Section("Calculator") {
                    // Master on/off
                    Toggle(isOn: Binding(
                        get: { settings.deltaBannerEnabled },
                        set: { settings.deltaBannerEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add / Remove Banner")
                            Text("Shows plates to add or remove when you change a weight")
                                .font(.caption)
                                .foregroundStyle(ThemeTokens.textMuted)
                        }
                    }
                    .tint(ThemeTokens.accent)

                    if settings.deltaBannerEnabled {
                        // Auto-dismiss toggle
                        Toggle(isOn: Binding(
                            get: { settings.deltaAutoDismissSeconds > 0 },
                            set: { settings.deltaAutoDismissSeconds = $0 ? 30 : 0 }
                        )) {
                            Text("Auto-dismiss")
                        }
                        .tint(ThemeTokens.accent)

                        // Seconds entry — only visible when auto-dismiss is on
                        if settings.deltaAutoDismissSeconds > 0 {
                            HStack {
                                Text("Dismiss after")
                                Spacer()
                                TextField("30", value: Binding(
                                    get: { settings.deltaAutoDismissSeconds },
                                    set: { settings.deltaAutoDismissSeconds = max(5, $0) }
                                ), format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 52)
                                Text("sec")
                                    .foregroundStyle(ThemeTokens.textMuted)
                            }
                        }
                    }
                }

                Section("Support") {
                    NavigationLink("Help & FAQ") {
                        HelpView(isPro: settings.isPro)
                    }
                }

                Section("Pro Status") {
                    HStack {
                        Text(settings.isPro ? "Pro — Unlocked" : "Free")
                            .foregroundStyle(settings.isPro ? ThemeTokens.accentPro : ThemeTokens.textSecondary)
                        Spacer()
                        if !settings.isPro {
                            Text("$1.99")
                                .foregroundStyle(ThemeTokens.accentPro)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(ThemeTokens.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(ThemeTokens.accent)
                }
            }
        }
        .sheet(isPresented: $showCustomBarSheet) {
            customBarWeightSheet
        }
    }

    private var customBarInputValue: Double? {
        guard let value = Double(customBarInput), value > 0 else { return nil }
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
                    Text("Enter a number greater than 0")
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let value = customBarInputValue {
                            settings.customBarWeight = value
                            settings.defaultBar = .custom
                            showCustomBarSheet = false
                        }
                    }
                    .foregroundStyle(customBarInputValue == nil ? ThemeTokens.textMuted : ThemeTokens.accent)
                    .disabled(customBarInputValue == nil)
                }
            }
        }
    }
}
