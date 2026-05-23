import SwiftUI

struct BarbellVisualizerView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @State private var swipeOffset: CGFloat = 0

    private var plates: [LoadedPlate] {
        vm.currentMode == .reverse ? vm.reversePlateStack : vm.plateResult.platesPerSide
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Bar sleeve (center)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.55))
                    .frame(width: geo.size.width * 0.85, height: 10)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 3)

                // Center collar marks
                HStack(spacing: geo.size.width * 0.85 - 40) {
                    Rectangle()
                        .fill(Color(white: 0.3))
                        .frame(width: 6, height: 24)
                    Rectangle()
                        .fill(Color(white: 0.3))
                        .frame(width: 6, height: 24)
                }

                // Plates — right side
                HStack(spacing: 0) {
                    Spacer()
                    plateStackView(plates: plates, mirrored: false)
                        .padding(.trailing, geo.size.width * 0.075)
                }

                // Plates — left side (mirrored)
                HStack(spacing: 0) {
                    plateStackView(plates: plates, mirrored: true)
                        .padding(.leading, geo.size.width * 0.075)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 100)
        .offset(x: swipeOffset)
        .gesture(
            DragGesture()
                .onChanged { swipeOffset = $0.translation.width * 0.3 }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        swipeOffset = 0
                    }
                    vm.resetWeight()
                    HapticManager.shared.swipeReset()
                }
        )
    }

    @ViewBuilder
    private func plateStackView(plates: [LoadedPlate], mirrored: Bool) -> some View {
        HStack(spacing: 1) {
            if mirrored {
                ForEach(plates.reversed()) { plate in
                    plateView(plate)
                }
            } else {
                ForEach(plates) { plate in
                    plateView(plate)
                }
            }
        }
    }

    @ViewBuilder
    private func plateView(_ plate: LoadedPlate) -> some View {
        let height = plateHeight(plate.weight)
        RoundedRectangle(cornerRadius: 3)
            .fill(ThemeTokens.plateColor(for: plate.weight, unit: settings.unit))
            .frame(width: plateWidth(plate.weight), height: height)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: plates.count)
    }

    private func plateHeight(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        switch lbs {
        case 99...:   return 80
        case 75..<99: return 72
        case 50..<75: return 64
        case 20..<50: return 52
        case 9..<20:  return 42
        default:      return 34
        }
    }

    private func plateWidth(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        return lbs >= 45 ? 14 : 10
    }
}
