import SwiftUI

struct ReverseModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            // Inventory limit warning — only shows if user has configured quantities
            if vm.reverseHitInventoryLimit {
                Label(
                    vm.reverseAllInventoryExhausted ? "Out of Plates" : "Some plates are at your inventory limit",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(ThemeTokens.warningAmber)
                .transition(.opacity)
            }

            // Plate rack grid
            PlateRackView(
                inventory: settings.activeInventory,
                unit: settings.unit,
                isAvailable: { vm.canAddPlate($0) }
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

            // Undo — tap to remove last plate; long-press to clear all
            HStack {
                Spacer()
                undoButton
                Spacer()
            }
            .padding(.bottom, 4)
        }
    }

    private var undoButton: some View {
        let isEmpty = vm.reversePlateStack.isEmpty
        return ZStack {
            Circle()
                .fill(isEmpty ? Color(white: 0.10) : ThemeTokens.accent.opacity(0.10))
            Circle()
                .strokeBorder(
                    isEmpty ? Color(white: 0.20) : ThemeTokens.accent.opacity(0.45),
                    lineWidth: 1.5
                )
            VStack(spacing: 3) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.subheadline.weight(.semibold))
                Text("Undo")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isEmpty ? ThemeTokens.textMuted : ThemeTokens.accent)
        }
        .frame(width: 68, height: 68)
        .contentShape(Circle())
        .onTapGesture {
            guard !isEmpty else { return }
            vm.undoLastPlate()
            HapticManager.shared.plateUndo()
        }
        .onLongPressGesture(minimumDuration: 0.55) {
            guard !isEmpty else { return }
            HapticManager.shared.swipeReset()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                vm.clearReverseStack()
            }
        }
        .disabled(isEmpty)
        .animation(.easeInOut(duration: 0.2), value: isEmpty)
    }

    // ≤3 types: single centered row. >3: 3-column grid (wraps to row 2).
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

        return Group {
            if grouped.count <= 3 {
                HStack(spacing: 16) {
                    ForEach(grouped, id: \.0) { weight, count in
                        plateCountCell(weight: weight, count: count)
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
                    ForEach(grouped, id: \.0) { weight, count in
                        plateCountCell(weight: weight, count: count)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func plateCountCell(weight: Double, count: Int) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ThemeTokens.plateColor(for: weight, unit: settings.unit))
                .frame(width: 9, height: 9)
            Text("\(count)×\(weight.weightString)")
                .font(.callout.weight(.bold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
    }
}
