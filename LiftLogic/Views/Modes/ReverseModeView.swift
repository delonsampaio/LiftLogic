import SwiftUI

struct ReverseModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            // Plate rack grid
            PlateRackView(
                inventory: settings.activeInventory,
                unit: settings.unit
            ) { plate in
                vm.addPlate(plate)
                let isHeavy = (settings.unit == .lbs ? plate.weight : WeightUnit.kg.convert(plate.weight, to: .lbs)) >= 45
                isHeavy ? HapticManager.shared.plateLarge() : HapticManager.shared.plateMedium()
            }

            // Plate breakdown — same style as CalcModeView, only shows when plates are added
            if !vm.reversePlateStack.isEmpty {
                plateSummaryPill
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Undo — circular disc, matches the plate-tool aesthetic
            HStack {
                Spacer()
                Button {
                    vm.undoLastPlate()
                    HapticManager.shared.plateUndo()
                } label: {
                    ZStack {
                        Circle()
                            .fill(vm.reversePlateStack.isEmpty
                                  ? Color(white: 0.10)
                                  : ThemeTokens.accent.opacity(0.10))
                        Circle()
                            .strokeBorder(
                                vm.reversePlateStack.isEmpty
                                    ? Color(white: 0.20)
                                    : ThemeTokens.accent.opacity(0.45),
                                lineWidth: 1.5
                            )
                        VStack(spacing: 3) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Undo")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(vm.reversePlateStack.isEmpty
                                         ? ThemeTokens.textMuted
                                         : ThemeTokens.accent)
                    }
                    .frame(width: 68, height: 68)
                }
                .buttonStyle(NumpadButtonStyle())
                .disabled(vm.reversePlateStack.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: vm.reversePlateStack.isEmpty)
                Spacer()
            }
            .padding(.bottom, 4)
        }
    }

    // Matches CalcModeView's plateBreakdownView — colored dot + "n× weight", centered
    private var plateSummaryPill: some View {
        let grouped = vm.reversePlateStack
            .reduce(into: [(Double, Int)]()) { acc, plate in
                if let idx = acc.firstIndex(where: { $0.0 == plate.weight }) {
                    acc[idx].1 += 1
                } else {
                    acc.append((plate.weight, 1))
                }
            }
            .sorted { $0.0 > $1.0 }   // heaviest first

        return GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(grouped, id: \.0) { weight, count in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ThemeTokens.plateColor(for: weight, unit: settings.unit))
                                .frame(width: 10, height: 10)
                            Text("\(count)× \(formatWeight(weight))")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(ThemeTokens.textPrimary)
                        }
                    }
                }
                .frame(minWidth: proxy.size.width, alignment: .center)
                .padding(.horizontal)
            }
        }
        .frame(height: 30)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
