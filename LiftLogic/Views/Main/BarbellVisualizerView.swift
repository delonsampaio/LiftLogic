import SwiftUI

struct BarbellVisualizerView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @State private var swipeOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    private var plates: [LoadedPlate] {
        vm.currentMode == .reverse ? vm.reversePlateStack : vm.plateResult.platesPerSide
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
                    .frame(width: geo.size.width * 0.85, height: 10)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 3)

                // Sleeve end caps — lighter, slightly taller, extend past the plates
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

                // Plates — right side (inset so sleeve tip stays visible)
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
        let lbsWeight = settings.unit == .lbs ? plate.weight : WeightUnit.kg.convert(plate.weight, to: .lbs)
        RoundedRectangle(cornerRadius: 3)
            .fill(ThemeTokens.plateColor(for: plate.weight, unit: settings.unit))
            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 2)
            .overlay {
                if height >= 40 {
                    Text(formatPlateLabel(plate.weight))
                        .font(.system(size: plateLabelSize(lbsWeight), weight: .black, design: .rounded))
                        .foregroundStyle(plateLabelColor(lbsWeight))
                        .rotationEffect(.degrees(-90))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(width: width, height: height)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    private func plateLabelSize(_ lbs: Double) -> CGFloat {
        switch lbs {
        case 44...:   return 12
        case 33..<44: return 10
        default:      return 9
        }
    }

    private func plateLabelColor(_ lbs: Double) -> Color {
        switch lbs {
        case 44...:   return .white                          // red plate
        case 33..<44: return .white                          // blue plate
        default:      return Color(white: 0.15)              // yellow/white/green — dark for contrast
        }
    }

    private func formatPlateLabel(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : "\(weight)"
    }

    private func plateHeight(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        switch lbs {
        case 44...:   return 76
        case 33..<44: return 64
        case 22..<33: return 54
        case 9..<22:  return 40
        case 4..<9:   return 30
        default:      return 22
        }
    }

    private func plateWidth(_ weight: Double) -> CGFloat {
        let lbs = settings.unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        switch lbs {
        case 44...:   return 16
        case 22..<44: return 13
        default:      return 10
        }
    }
}
