import SwiftUI

struct BarbellVisualizerView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @State private var swipeOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

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
                if vm.isSingleSided {
                    singleSidedBarbell(geo: geo)
                } else {
                    symmetricBarbell(geo: geo)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 110)
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
                    vm.resetWeight()
                    HapticManager.shared.swipeReset()
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    vm.resetWeight()
                    HapticManager.shared.swipeReset()
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.55)
                .onEnded { _ in
                    HapticManager.shared.swipeReset()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { swipeOffset = 440 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { vm.resetWeight() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        swipeOffset = -18
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { swipeOffset = 0 }
                    }
                }
        )
    }

    @ViewBuilder
    private func symmetricBarbell(geo: GeometryProxy) -> some View {
        // Ground shadow
        Ellipse()
            .fill(Color.black.opacity(0.25))
            .frame(width: geo.size.width * 0.72, height: 6)
            .blur(radius: 5)
            .offset(y: 30)

        // Main bar shaft
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(white: 0.55))
            .frame(width: geo.size.width * 0.85, height: 10)
            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 3)

        // Sleeve end caps
        HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.72))
                .frame(width: geo.size.width * 0.075, height: 15)
                .padding(.leading, geo.size.width * 0.055)
            Spacer()
        }
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.72))
                .frame(width: geo.size.width * 0.075, height: 15)
                .padding(.trailing, geo.size.width * 0.055)
        }

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
                .padding(.trailing, geo.size.width * 0.115)
        }

        // Plates — left side (mirrored)
        HStack(spacing: 0) {
            plateStackView(plates: plates, mirrored: true)
                .padding(.leading, geo.size.width * 0.115)
            Spacer()
        }
    }

    @ViewBuilder
    private func singleSidedBarbell(geo: GeometryProxy) -> some View {
        // Ground shadow — offset right to match the single sleeve
        Ellipse()
            .fill(Color.black.opacity(0.25))
            .frame(width: geo.size.width * 0.55, height: 6)
            .blur(radius: 5)
            .offset(x: geo.size.width * 0.12, y: 30)

        // Bar shaft — extends from center-left to right edge (anchor left, sleeve right)
        HStack(spacing: 0) {
            // Anchor block (floor sleeve / machine mount)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.35))
                .frame(width: 18, height: 22)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            // Shaft from anchor to right
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.55))
                .frame(width: geo.size.width * 0.62, height: 10)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 3)
            Spacer()
        }
        .padding(.leading, geo.size.width * 0.07)

        // Right sleeve end cap
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.72))
                .frame(width: geo.size.width * 0.075, height: 15)
                .padding(.trailing, geo.size.width * 0.055)
        }

        // Single collar mark (right of center)
        HStack {
            Spacer()
            Rectangle()
                .fill(Color(white: 0.3))
                .frame(width: 6, height: 24)
                .padding(.trailing, geo.size.width * 0.28)
        }

        // Plates — right side only
        HStack(spacing: 0) {
            Spacer()
            plateStackView(plates: plates, mirrored: false)
                .padding(.trailing, geo.size.width * 0.115)
        }
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
    }

    private func plateHeight(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        switch lbs {
        case 44...:   return 76
        case 33..<44: return 64
        case 22..<33: return 54
        case 9..<22:  return 40
        case 4..<9:   return 30
        case 2..<4:   return 22   // 2.5 lb / 1.25 kg
        default:      return 12   // micro plates (< 2 lb)
        }
    }

    private func plateWidth(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        switch lbs {
        case 44...:   return 16
        case 22..<44: return 13
        case 2...:    return 10
        default:      return 7    // micro plates (< 2 lb) — very thin
        }
    }
}
