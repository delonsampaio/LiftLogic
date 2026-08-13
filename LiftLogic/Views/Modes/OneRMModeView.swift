import SwiftUI

struct OneRMModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.7 : 1.0 }

    var body: some View {
        VStack(spacing: 20) {
            if vm.targetWeight == 0 {
                Text("Enter the weight you lifted in CALC mode")
                    .font(sizeClass == .regular ? .title3 : .subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Reps stepper
                        HStack(spacing: 16) {
                            Text("Reps lifted:")
                                .foregroundStyle(ThemeTokens.textSecondary)
                                .font(sizeClass == .regular ? .title3.weight(.medium) : .subheadline.weight(.medium))

                            Stepper("\(vm.oneRMReps)", value: Binding(
                                get: { vm.oneRMReps },
                                set: { vm.oneRMReps = $0 }
                            ), in: 1...OneRMEngine.maxReliableReps)
                            .font(sizeClass == .regular ? .title3.weight(.medium) : .body)
                            .controlSize(sizeClass == .regular ? .large : .regular)
                            .fixedSize()
                        }
                        .padding(.horizontal)

                        // RPE stepper (#61)
                        HStack(spacing: 16) {
                            Text("RPE:")
                                .foregroundStyle(ThemeTokens.textSecondary)
                                .font(sizeClass == .regular ? .title3.weight(.medium) : .subheadline.weight(.medium))

                            Stepper(String(format: "%.1f", vm.oneRMRPE), value: Binding(
                                get: { vm.oneRMRPE },
                                set: { vm.oneRMRPE = $0 }
                            ), in: 6.0...10.0, step: 0.5)
                            .font(sizeClass == .regular ? .title3.weight(.medium) : .body)
                            .controlSize(sizeClass == .regular ? .large : .regular)
                            .fixedSize()
                        }
                        .padding(.horizontal)

                        if vm.oneRMReps > 10 {
                            Text("Estimates lose accuracy above 10 reps")
                                .font(sizeClass == .regular ? .subheadline : .caption2)
                                .foregroundStyle(ThemeTokens.textMuted)
                                .padding(.horizontal)
                        }

                        // Results
                        let result = vm.oneRMResult

                        VStack(spacing: 12) {
                            oneRMRow(label: "Epley", value: result.epley, unit: settings.unit.symbol)
                            oneRMRow(label: "Brzycki", value: result.brzycki, unit: settings.unit.symbol)

                            if let rpeEstimate = vm.rpeEstimatedOneRM {
                                oneRMRow(label: "RPE Est.", value: rpeEstimate, unit: settings.unit.symbol)
                            } else {
                                Text("RPE estimate unavailable above 12 reps")
                                    .font(sizeClass == .regular ? .subheadline : .caption2)
                                    .foregroundStyle(ThemeTokens.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Divider().opacity(0.2)

                            // Average — tap to load
                            Button {
                                settings.savedOneRM = result.average.rounded()
                                vm.loadWeight(result.average.rounded())
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    vm.currentMode = .calc
                                }
                                HapticManager.shared.numpadKey()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Average (Epley/Brzycki)")
                                            .font(sizeClass == .regular ? .title3.weight(.semibold) : .caption.weight(.semibold))
                                            .foregroundStyle(ThemeTokens.accentPro)
                                        Text("Tap to load into CALC")
                                            .font(sizeClass == .regular ? .subheadline : .caption2)
                                            .foregroundStyle(ThemeTokens.textMuted)
                                    }
                                    Spacer()
                                    Text("\(Int(result.average.rounded())) \(settings.unit.symbol)")
                                        .font(sizeClass == .regular ? .title.weight(.black) : .title2.weight(.black))
                                        .foregroundStyle(ThemeTokens.accentPro)
                                }
                                .padding(16 * scale)
                                .background(RoundedRectangle(cornerRadius: 12).fill(ThemeTokens.accentPro.opacity(0.12)))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(ThemeTokens.accentPro.opacity(0.25), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        // Relative strength (#76)
                        if let sex = settings.sex, settings.bodyWeight > 0 {
                            let bodyweightKg = settings.unit.convert(settings.bodyWeight, to: .kg)
                            let liftedKg = settings.unit.convert(vm.oneRMResult.average, to: .kg)
                            let strength = vm.relativeStrengthResult(bodyweightKg: bodyweightKg, sex: sex, liftedKg: liftedKg)

                            VStack(spacing: 12) {
                                Text("Relative Strength")
                                    .font(sizeClass == .regular ? .title3.weight(.semibold) : .caption.weight(.semibold))
                                    .foregroundStyle(ThemeTokens.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                strengthRow(label: "Wilks", value: strength.wilks)
                                strengthRow(label: "DOTS", value: strength.dots)
                                strengthRow(label: "IPF GL", value: strength.ipfGL)

                                Text("IPF GL Points are calibrated for a full 3-lift total, so a single lift scores much lower than Wilks/DOTS on the same weight.")
                                    .font(sizeClass == .regular ? .subheadline : .caption2)
                                    .foregroundStyle(ThemeTokens.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal)
                        } else {
                            Text("Set bodyweight & sex in Settings to see your strength score")
                                .font(sizeClass == .regular ? .subheadline : .caption2)
                                .foregroundStyle(ThemeTokens.textMuted)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }

    @ViewBuilder
    private func oneRMRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(sizeClass == .regular ? .title2.weight(.medium) : .subheadline.weight(.medium))
                .foregroundStyle(ThemeTokens.textSecondary)
            Spacer()
            Text("\(Int(value.rounded())) \(unit)")
                .font(sizeClass == .regular ? .title.weight(.semibold) : .callout.weight(.semibold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func strengthRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(sizeClass == .regular ? .title2.weight(.medium) : .subheadline.weight(.medium))
                .foregroundStyle(ThemeTokens.textSecondary)
            Spacer()
            Text("\(Int(value.rounded()))")
                .font(sizeClass == .regular ? .title.weight(.semibold) : .callout.weight(.semibold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
        .padding(.horizontal)
    }
}
