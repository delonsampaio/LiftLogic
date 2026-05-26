import SwiftUI
import StoreKit

struct MainView: View {
    @State private var settings = AppSettings()
    @State private var vm: CalculatorViewModel
    @State private var timer = TimerService()
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var showSavedSetups = false
    @State private var showTimer = false
    @Environment(\.requestReview) private var requestReview

    init() {
        let s = AppSettings()
        _settings = State(initialValue: s)
        _vm = State(initialValue: CalculatorViewModel(settings: s))
    }

    var body: some View {
        ZStack {
            ThemeTokens.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar — ZStack so title is always geometrically centered
                // regardless of how many icons are on each side
                ZStack {
                    // Center layer: title
                    Text("LiftLogic")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ThemeTokens.textMuted)
                        .frame(maxWidth: .infinity)

                    // Left side: settings
                    HStack {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundStyle(ThemeTokens.textMuted)
                        }
                        .accessibilityLabel("Settings")
                        Spacer()
                    }

                    // Right side: evenly spaced action icons
                    HStack {
                        Spacer()
                        HStack(spacing: 20) {
                            Button {
                                ShareService.share(vm: vm, settings: settings)
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
                                    .foregroundStyle(ThemeTokens.textMuted)
                            }
                            .accessibilityLabel("Share lift")

                            Button {
                                guard settings.isPro else { showPaywall = true; return }
                                showTimer = true
                            } label: {
                                if timer.state == .running || timer.state == .paused {
                                    HStack(spacing: 4) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(timer.formattedTime)
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .contentTransition(.numericText())
                                            .animation(.spring(response: 0.3), value: timer.remainingSeconds)
                                    }
                                    .foregroundStyle(ThemeTokens.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(ThemeTokens.accent.opacity(0.15)))
                                    .overlay(Capsule().strokeBorder(ThemeTokens.accent.opacity(0.35), lineWidth: 1))
                                } else {
                                    Image(systemName: "timer")
                                        .font(.system(size: 20))
                                        .foregroundStyle(ThemeTokens.textMuted)
                                }
                            }
                            .accessibilityLabel(timer.state == .running ? "Rest timer running, \(timer.formattedTime) remaining" : "Rest timer")

                            if settings.isPro {
                                Button {
                                    showSavedSetups = true
                                } label: {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 20))
                                        .foregroundStyle(ThemeTokens.textMuted)
                                }
                                .accessibilityLabel("Saved setups")
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
                                .accessibilityLabel("Upgrade to Pro")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Readout
                ReadoutView(vm: vm, settings: settings)
                    .padding(.vertical, 8)

                // Single Side mode indicator — visible reminder that calculation semantics changed
                if vm.isSingleSided {
                    Label("Single Side", systemImage: "arrow.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(ThemeTokens.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(ThemeTokens.accent.opacity(0.15)))
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.easeInOut(duration: 0.2), value: vm.isSingleSided)
                        .padding(.bottom, 4)
                }

                // Barbell hero
                BarbellVisualizerView(vm: vm, settings: settings)
                    .padding(.vertical, 4)

                // Sleeve space warning — shown when many plates are loaded
                let visiblePlateCount = vm.currentMode == .reverse
                    ? vm.reversePlateStack.count
                    : vm.plateResult.platesPerSide.count
                if visiblePlateCount >= 9 {
                    Label("Check sleeve space", systemImage: "exclamationmark.triangle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ThemeTokens.warningAmber)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeInOut(duration: 0.25), value: visiblePlateCount >= 9)
                }

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
        .sheet(isPresented: $showSavedSetups) {
            SavedSetupsView(settings: settings, vm: vm)
        }
        .sheet(isPresented: $showTimer) {
            RestTimerView(timer: timer, isPresented: $showTimer)
                .presentationDetents([.medium])
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            timer.reattachIfNeeded()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: settings.successfulCalculationCount) { _, count in
            if count == 5 || count == 20 || count == 75 {
                requestReview()
            }
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
