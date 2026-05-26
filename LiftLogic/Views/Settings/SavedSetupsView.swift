import SwiftUI

struct SavedSetupsView: View {
    let settings: AppSettings
    let vm: CalculatorViewModel
    @State private var showSaveSheet = false
    @State private var newSetupName = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if settings.savedSetups.isEmpty {
                    Text("No saved setups. Save the current configuration to recall it later.")
                        .foregroundStyle(ThemeTokens.textMuted)
                        .font(.subheadline)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(settings.savedSetups) { setup in
                        setupRow(setup)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { settings.savedSetups.remove(at: $0) }
                    }
                }
            }
            .navigationTitle("Saved Setups")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(ThemeTokens.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newSetupName = ""
                        showSaveSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(ThemeTokens.accent)
                    }
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                saveSetupSheet
            }
        }
    }

    @ViewBuilder
    private func setupRow(_ setup: SavedSetup) -> some View {
        Button {
            vm.loadWeight(setup.weight)
            vm.selectedBar = setup.barType
            vm.collarType = setup.collarType
            vm.isSingleSided = setup.isSingleSided
            settings.unit = setup.unit
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(setup.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThemeTokens.textPrimary)
                    Text("\(setup.weight.weightString) \(setup.unit.symbol) · \(setup.barType.displayName)")
                        .font(.caption)
                        .foregroundStyle(ThemeTokens.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ThemeTokens.textMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private var saveSetupSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Name this setup")
                    .font(.headline)
                    .foregroundStyle(ThemeTokens.textPrimary)
                TextField("e.g. Competition Squat", text: $newSetupName)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(ThemeTokens.backgroundCard))
                    .foregroundStyle(ThemeTokens.textPrimary)
                    .padding(.horizontal)
                Text("\(vm.targetWeight.weightString) \(settings.unit.symbol) · \(vm.selectedBar.displayName)")
                    .foregroundStyle(ThemeTokens.textMuted)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.top, 32)
            .background(ThemeTokens.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Save Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showSaveSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let setup = SavedSetup(
                            id: UUID(),
                            name: newSetupName.isEmpty ? "Setup \(settings.savedSetups.count + 1)" : newSetupName,
                            weight: vm.targetWeight,
                            barType: vm.selectedBar,
                            collarType: vm.collarType,
                            unit: settings.unit,
                            isSingleSided: vm.isSingleSided,
                            createdAt: Date()
                        )
                        settings.saveSetup(setup)
                        showSaveSheet = false
                    }
                    .foregroundStyle(ThemeTokens.accent)
                }
            }
        }
    }

}
