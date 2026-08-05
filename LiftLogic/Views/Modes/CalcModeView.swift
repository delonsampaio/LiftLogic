import SwiftUI

/// The compact-width CALC screen: output panel above the input cluster.
struct CalcModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            CalcPanelView(vm: vm, settings: settings)
            CalcInputView(vm: vm, settings: settings)
        }
    }
}
