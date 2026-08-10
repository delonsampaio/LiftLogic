import SwiftUI
import StoreKit

/// Tracks the widest top-bar side cluster so the title can reserve space for it.
private struct TopBarSideWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MainView: View {
    @State private var settings: AppSettings
    @State private var vm: CalculatorViewModel
    @State private var timer = TimerService()
    @State private var store = StoreKitService()
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var showSavedSetups = false
    @State private var showLiftingPartner = false
    @State private var showTimer = false
    // Widest of the two top-bar side clusters — the title reserves this much
    // horizontal padding on each side so it can never overlap either side,
    // even when the running-timer badge widens the trailing cluster.
    @State private var topBarSideWidth: CGFloat = 0
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase

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
                    // Center layer: title. Reserves horizontal space matching the wider
                    // side cluster so it can never overlap either side — the trailing
                    // cluster grows when the running-timer badge shows its digits.
                    Text("LiftLogic")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(ThemeTokens.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, topBarSideWidth + 8)

                    // Left side: settings + rest timer (kept together so the timer
                    // button doesn't jump sides between its idle and running states)
                    HStack {
                        HStack(spacing: 12) {
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.title3)
                                    .foregroundStyle(ThemeTokens.textMuted)
                            }
                            .accessibilityLabel("Settings")

                            Button {
                                guard settings.isPro else { showPaywall = true; return }
                                showTimer = true
                            } label: {
                                if timer.state == .running || timer.state == .paused {
                                    HStack(spacing: 4) {
                                        Image(systemName: "timer")
                                            .font(.caption.weight(.semibold))
                                        Text(timer.formattedTime)
                                            .font(.footnote.weight(.bold))
                                            .monospacedDigit()
                                            .contentTransition(.numericText())
                                            .animation(.spring(response: 0.3), value: timer.remainingSeconds)
                                    }
                                    .foregroundStyle(settings.accentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(settings.accentColor.opacity(0.15)))
                                    .overlay(Capsule().strokeBorder(settings.accentColor.opacity(0.35), lineWidth: 1))
                                } else {
                                    Image(systemName: "timer")
                                        .font(.title3)
                                        .foregroundStyle(ThemeTokens.textMuted)
                                }
                            }
                            .accessibilityLabel(timer.state == .running ? "Rest timer running, \(timer.formattedTime) remaining" : "Rest timer")
                        }
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: TopBarSideWidthKey.self, value: geo.size.width)
                            }
                        }

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

                            if settings.isPro {
                                Button {
                                    showSavedSetups = true
                                } label: {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 20))
                                        .foregroundStyle(ThemeTokens.textMuted)
                                }
                                .accessibilityLabel("Saved setups")

                                Button {
                                    showLiftingPartner = true
                                } label: {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 20))
                                        .foregroundStyle(ThemeTokens.textMuted)
                                }
                                .accessibilityLabel("Lifting Partner Mode")
                            } else {
                                Button {
                                    showPaywall = true
                                } label: {
                                    Text("PRO")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(ThemeTokens.accentPro)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(ThemeTokens.accentPro.opacity(0.15)))
                                }
                                .accessibilityLabel("Upgrade to Pro")
                            }
                        }
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: TopBarSideWidthKey.self, value: geo.size.width)
                            }
                        }
                    }
                }
                .onPreferenceChange(TopBarSideWidthKey.self) { topBarSideWidth = $0 }
                .padding(.horizontal)
                .padding(.top, 8)

                compactBody
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            ProPaywallView(settings: settings, store: store)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(settings: settings, vm: vm)
        }
        .fullScreenCover(isPresented: $showSavedSetups) {
            SavedSetupsView(settings: settings, vm: vm)
        }
        .fullScreenCover(isPresented: $showLiftingPartner) {
            LiftingPartnerView(vm: vm, settings: settings, onSetupLoaded: { showLiftingPartner = false })
        }
        .sheet(isPresented: $showTimer) {
            RestTimerView(timer: timer, settings: settings, isPresented: $showTimer)
                .presentationDetents([.medium])
                .presentationBackgroundInteraction(.enabled)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            timer.reattachIfNeeded()
        }
        .task {
            store.start(settings: settings)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { timer.syncFromActivity() }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: settings.successfulCalculationCount) { _, count in
            if count == 5 || count == 20 || count == 75 {
                requestReview()
            }
        }
        .onOpenURL { url in
            guard let weight = WidgetDeepLink.parseCalcWeight(from: url) else { return }
            vm.loadWeight(weight)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                vm.currentMode = .calc
            }
        }
    }

    @ViewBuilder
    private var heroSection: some View {
        ReadoutView(vm: vm, settings: settings)
            .padding(.vertical, 8)

        if vm.isSingleSided {
            Label("Single Side", systemImage: "arrow.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(settings.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(settings.accentColor.opacity(0.15)))
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.2), value: vm.isSingleSided)
                .padding(.bottom, 4)
        }

        BarbellVisualizerView(vm: vm, settings: settings)
            .padding(.vertical, 4)

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

        QuickToggleStripView(vm: vm, settings: settings)
            .padding(.vertical, 6)

        ModePillStripView(vm: vm, settings: settings, showPaywall: $showPaywall)
            .padding(.vertical, 8)
    }

    // Single column on both iPhone and iPad — elements scale up via each
    // subview's own horizontalSizeClass check, but the layout stays unified.
    @ViewBuilder
    private var compactBody: some View {
        heroSection
        Divider().opacity(0.15)
        controlZone
            .padding(.top, 8)
        Spacer(minLength: 0)
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
