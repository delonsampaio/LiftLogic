import SwiftUI

/// The CALC output panel: empty-state prompt or the plate breakdown.
struct CalcPanelView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.4 : 1.0 }

    var body: some View {
        ZStack {
            if vm.targetWeight == 0 {
                EmptyStateView()
                    .transition(.opacity)
            }
            if vm.targetWeight > 0 && !vm.plateResult.platesPerSide.isEmpty {
                plateBreakdownView
                    .transition(.opacity)
            }
        }
        .frame(minHeight: 52)
        .animation(.easeInOut(duration: 0.2), value: vm.targetWeight > 0)
    }

    private var plateBreakdownView: some View {
        let grouped = vm.plateResult.grouped
        return Group {
            if grouped.count <= 3 {
                HStack(spacing: 16) {
                    ForEach(grouped, id: \.weight) { group in
                        plateCell(group)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
            } else {
                let columns = [
                    GridItem(.flexible(), alignment: .center),
                    GridItem(.flexible(), alignment: .center),
                    GridItem(.flexible(), alignment: .center)
                ]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(grouped, id: \.weight) { group in
                        plateCell(group)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func plateCell(_ group: (weight: Double, count: Int)) -> some View {
        let totalCount = group.count * (vm.isSingleSided ? 1 : 2)
        return HStack(spacing: 6) {
            Circle()
                .fill(ThemeTokens.plateColor(for: group.weight, unit: settings.unit))
                .frame(width: 10 * scale, height: 10 * scale)
            Text("\(totalCount)×\(group.weight.weightString)")
                .font(sizeClass == .regular ? .title3.weight(.bold) : .body.weight(.bold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
    }
}
