import SwiftUI

struct SettingsView: View {
    let settings: AppSettings
    let vm: CalculatorViewModel
    @State private var showCustomBarSheet = false
    @State private var customBarInput = ""
    @FocusState private var numericFieldFocused: Bool
    @FocusState private var customBarFocused: Bool
    @State private var editingPreset: RestTimerPreset?
    @State private var showNewPresetSheet = false
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

                // Plate inventory
                Section("Plate Inventory") {
                    NavigationLink("Pounds (lbs)") {
                        PlateInventoryView(
                            inventory: Binding(
                                get: { settings.lbsInventory },
                                set: { settings.lbsInventory = $0 }
                            ),
                            unit: .lbs,
                            isPro: settings.isPro,
                            accentColor: settings.accentColor
                        )
                    }
                    NavigationLink("Kilograms (kg)") {
                        PlateInventoryView(
                            inventory: Binding(
                                get: { settings.kgInventory },
                                set: { settings.kgInventory = $0 }
                            ),
                            unit: .kg,
                            isPro: settings.isPro,
                            accentColor: settings.accentColor
                        )
                    }
                }

                if settings.isPro {
                    Section {
                        HStack {
                            Text("Bodyweight")
                            Spacer()
                            TextField("0", value: Binding(
                                get: { settings.bodyWeight },
                                set: { settings.bodyWeight = $0 }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .focused($numericFieldFocused)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            Text(settings.unit.symbol)
                                .foregroundStyle(ThemeTokens.textMuted)
                        }
                        Picker("Sex", selection: Binding(
                            get: { settings.sex },
                            set: { settings.sex = $0 }
                        )) {
                            ForEach(Sex.allCases, id: \.self) { sex in
                                Text(sex.displayName).tag(Sex?.some(sex))
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Bodyweight & Sex")
                    } footer: {
                        Text("Used for the bodyweight ratio under your readout, and unlocks Wilks/DOTS/IPF GL Points scoring in 1RM mode.")
                            .foregroundStyle(ThemeTokens.textMuted)
                    }
                }

                if settings.isPro {
                    Section {
                        ForEach(settings.warmupPercentages) { step in
                            Stepper(value: Binding(
                                get: { settings.warmupPercentages.first { $0.id == step.id }?.percentage ?? step.percentage },
                                set: { settings.updateWarmupPercentage(id: step.id, percentage: $0) }
                            ), in: 10...150, step: 5) {
                                Text("\(step.percentage)%")
                                    .foregroundStyle(ThemeTokens.textPrimary)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { settings.warmupPercentages[$0].id }.forEach { settings.deleteWarmupPercentage(id: $0) }
                        }
                        if settings.warmupPercentages.count < 8 {
                            Button("Add Step") { settings.addWarmupPercentage() }
                                .foregroundStyle(settings.accentColor)
                        }
                        Button("Reset to Default") { settings.resetWarmupPercentagesToDefault() }
                            .foregroundStyle(ThemeTokens.textMuted)
                    } header: {
                        Text("Warmup %")
                    } footer: {
                        Text("The ladder shown in WARMUP mode. Defaults to 50/60/70/80/90% of your target weight.")
                            .foregroundStyle(ThemeTokens.textMuted)
                    }
                }

                if settings.isPro {
                    Section("Rest Timer") {
                        ForEach(settings.restTimerPresets) { preset in
                            Button {
                                editingPreset = preset
                            } label: {
                                HStack {
                                    Text(preset.name).foregroundStyle(ThemeTokens.textPrimary)
                                    Spacer()
                                    Text(restTimerDurationLabel(preset.seconds))
                                        .foregroundStyle(ThemeTokens.textMuted)
                                        .monospaced()
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { settings.restTimerPresets[$0].id }.forEach { settings.deleteTimerPreset(id: $0) }
                        }
                        Button("Add Preset") { showNewPresetSheet = true }
                            .foregroundStyle(settings.accentColor)
                    }
                }

                if settings.isPro {
                    Section {
                        Toggle(isOn: Binding(
                            get: { settings.decimalPrecisionLockEnabled },
                            set: { settings.decimalPrecisionLockEnabled = $0 }
                        )) {
                            Text("Decimal Precision Lock")
                        }
                        .tint(settings.accentColor)
                    } header: {
                        Text("Decimal Precision Lock")
                    } footer: {
                        Text("When enabled, weights round to the nearest increment loadable with your enabled plates — no more targets that aren't physically achievable.")
                            .foregroundStyle(ThemeTokens.textMuted)
                    }
                }

                if settings.isPro {
                    Section {
                        HStack(spacing: 16) {
                            ForEach(AccentColorOption.allCases) { option in
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if settings.accentColorOption == option {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .font(.caption.weight(.bold))
                                        }
                                    }
                                    .onTapGesture { settings.accentColorOption = option }
                                    .accessibilityElement()
                                    .accessibilityLabel(option.displayName)
                                    .accessibilityAddTraits(settings.accentColorOption == option ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Accent Color")
                    } footer: {
                        Text("Changes the app's accent color everywhere, including your Share My Lift card.")
                            .foregroundStyle(ThemeTokens.textMuted)
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
                    .tint(settings.accentColor)

                    if settings.deltaBannerEnabled {
                        // Auto-dismiss toggle
                        Toggle(isOn: Binding(
                            get: { settings.deltaAutoDismissSeconds > 0 },
                            set: { settings.deltaAutoDismissSeconds = $0 ? 30 : 0 }
                        )) {
                            Text("Auto-dismiss")
                        }
                        .tint(settings.accentColor)

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
                                .focused($numericFieldFocused)
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
                        HelpView(isPro: settings.isPro, accentColor: settings.accentColor)
                    }
                }

                Section("Pro Status") {
                    HStack {
                        Text(settings.isPro ? "Pro — Unlocked" : "Free")
                            .foregroundStyle(settings.isPro ? ThemeTokens.accentPro : ThemeTokens.textSecondary)
                        Spacer()
                        if !settings.isPro {
                            Text("$0.99")
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
                        .foregroundStyle(settings.accentColor)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { numericFieldFocused = false }
                }
            }
        }
        .sheet(isPresented: $showCustomBarSheet) {
            customBarWeightSheet
        }
        .sheet(isPresented: $showNewPresetSheet) {
            TimerPresetEditorSheet(initialName: "", initialSeconds: 120, accentColor: settings.accentColor) { name, seconds in
                settings.addTimerPreset(name: name, seconds: seconds)
            }
        }
        .sheet(item: $editingPreset) { preset in
            TimerPresetEditorSheet(initialName: preset.name, initialSeconds: preset.seconds, accentColor: settings.accentColor) { name, seconds in
                settings.updateTimerPreset(RestTimerPreset(id: preset.id, name: name, seconds: seconds))
            }
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
