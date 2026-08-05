import SwiftUI

/// The output panel for the current mode. On iPad this lives in the right column;
/// on iPhone it is composed into each mode view.
struct ModePanelView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @ViewBuilder
    var body: some View {
        switch vm.currentMode {
        case .calc:    CalcPanelView(vm: vm, settings: settings)
        case .warmup:  WarmupModeView(vm: vm, settings: settings)
        case .oneRM:   OneRMModeView(vm: vm, settings: settings)
        case .reverse: ReverseModeView(vm: vm, settings: settings)
        }
    }
}
