import SwiftUI

struct BarbellVisualizerView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var swipeOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    private var scale: CGFloat { sizeClass == .regular ? 1.5 : 1.0 }

    private var plates: [LoadedPlate] {
        if vm.currentMode == .reverse {
            // Heaviest plates innermost (closest to collar), lightest outermost
            return vm.reversePlateStack.sorted { $0.weight > $1.weight }
        }
        return vm.plateResult.platesPerSide
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                // Ground shadow
                Ellipse()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: geo.size.width * 0.72, height: 6)
                    .blur(radius: 5)
                    .offset(y: 30)

                // Main bar shaft
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.55))
                    .frame(width: geo.size.width * 0.85, height: 10 * scale)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 3)

                // Sleeve end caps — lighter, slightly taller, extend past the plates
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.72))
                        .frame(width: geo.size.width * 0.075, height: 15 * scale)
                        .padding(.leading, geo.size.width * 0.055)
                    Spacer()
                }
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.72))
                        .frame(width: geo.size.width * 0.075, height: 15 * scale)
                        .padding(.trailing, geo.size.width * 0.055)
                }

                // Center collar marks
                HStack(spacing: geo.size.width * 0.85 - 40) {
                    Rectangle()
                        .fill(Color(white: 0.3))
                        .frame(width: 6 * scale, height: 24 * scale)
                    Rectangle()
                        .fill(Color(white: 0.3))
                        .frame(width: 6 * scale, height: 24 * scale)
                }

                // Plates — right side (inset so sleeve tip stays visible)
                HStack(spacing: 0) {
                    Spacer()
                    plateStackView(plates: plates, mirrored: false)
                        .padding(.trailing, geo.size.width * 0.115)
                }

                // Plates — left side (mirrored) — hidden in single-sided mode
                if !vm.isSingleSided {
                    HStack(spacing: 0) {
                        plateStackView(plates: plates, mirrored: true)
                            .padding(.leading, geo.size.width * 0.115)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 110 * scale)
        .scaleEffect(pulseScale)
        .offset(x: swipeOffset)
        .onChange(of: plates.count) { _, _ in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.35)) { pulseScale = 1.05 }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.12)) { pulseScale = 1.0 }
        }
        .gesture(
            DragGesture()
                .onChanged { swipeOffset = $0.translation.width * 0.3 }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { swipeOffset = 0 }
                    if vm.currentMode == .reverse {
                        withAnimation { vm.clearReverseStack() }
                    } else {
                        vm.resetWeight()
                    }
                    HapticManager.shared.swipeReset()
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    if vm.currentMode != .reverse {
                        vm.resetWeight()
                        HapticManager.shared.swipeReset()
                    }
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.55)
                .onEnded { _ in
                    HapticManager.shared.swipeReset()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { swipeOffset = 440 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        if vm.currentMode == .reverse {
                            vm.clearReverseStack()
                        } else {
                            vm.resetWeight()
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        swipeOffset = -18
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { swipeOffset = 0 }
                    }
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
        .animation(.spring(response: 0.22, dampingFraction: 0.52), value: plates.map(\.id))
    }

    @ViewBuilder
    private func plateView(_ plate: LoadedPlate) -> some View {
        let height = plateHeight(plate.weight)
        let width = plateWidth(plate.weight)
        RoundedRectangle(cornerRadius: 3)
            .fill(ThemeTokens.plateColor(for: plate.weight, unit: settings.unit))
            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 2)
            .frame(width: width, height: height)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
            .onTapGesture {
                guard vm.currentMode == .reverse else { return }
                withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) {
                    vm.removePlate(id: plate.id)
                }
                HapticManager.shared.plateUndo()
            }
    }

    private func plateHeight(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        let base: CGFloat
        switch lbs {
        case 44...:   base = 76
        case 33..<44: base = 64
        case 22..<33: base = 54
        case 9..<22:  base = 40
        case 4..<9:   base = 30
        case 2..<4:   base = 22   // 2.5 lb / 1.25 kg
        default:      base = 12   // micro plates (< 2 lb)
        }
        return base * scale
    }

    private func plateWidth(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        let base: CGFloat
        switch lbs {
        case 44...:   base = 16
        case 22..<44: base = 13
        case 2...:    base = 10
        default:      base = 7   // micro plates (< 2 lb) — very thin
        }
        return base * scale
    }
}
