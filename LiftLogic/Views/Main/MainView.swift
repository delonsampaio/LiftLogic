import SwiftUI

struct MainView: View {
    @State private var settings = AppSettings()
    @State private var vm: CalculatorViewModel
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var showSavedSetups = false

    init() {
        let s = AppSettings()
        _settings = State(initialValue: s)
        _vm = State(initialValue: CalculatorViewModel(settings: s))
    }

    var body: some View {
        ZStack {
            ThemeTokens.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(ThemeTokens.textMuted)
                    }

                    Spacer()

                    Text("LiftLogic")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ThemeTokens.textMuted)

                    Spacer()

                    if settings.isPro {
                        Button {
                            showSavedSetups = true
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.system(size: 20))
                                .foregroundStyle(ThemeTokens.textMuted)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Text("PRO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ThemeTokens.accentPro)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(ThemeTokens.accentPro.opacity(0.15)))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Readout
                ReadoutView(vm: vm, settings: settings)
                    .padding(.vertical, 8)

                // Barbell hero
                BarbellVisualizerView(vm: vm, settings: settings)
                    .padding(.vertical, 4)

                // Quick toggle strip
                QuickToggleStripView(vm: vm, settings: settings)
                    .padding(.vertical, 6)

                // Mode pills
                ModePillStripView(vm: vm, settings: settings, showPaywall: $showPaywall)
                    .padding(.vertical, 8)

                Divider().opacity(0.15)

                // Control zone — morphs per mode
                controlZone
                    .padding(.top, 8)

                Spacer(minLength: 0)
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView(settings: settings)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, vm: vm)
        }
    }

    @ViewBuilder
    private var controlZone: some View {
        switch vm.currentMode {
        case .calc:
            CalcModeView(vm: vm, settings: settings)
                .transition(.blurReplace)
        case .warmup:
            WarmupModeView(vm: vm, settings: settings)
                .transition(.blurReplace)
        case .oneRM:
            OneRMModeView(vm: vm, settings: settings)
                .transition(.blurReplace)
        case .reverse:
            ReverseModeView(vm: vm, settings: settings)
                .transition(.blurReplace)
        }
    }
}
