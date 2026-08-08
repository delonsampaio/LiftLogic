import SwiftUI

struct OneRMModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 20) {
            if vm.targetWeight == 0 {
                Text("Enter the weight you lifted in CALC mode")
                    .font(.subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding()
            } else {
                // Reps stepper
                HStack(spacing: 16) {
                    Text("Reps lifted:")
                        .foregroundStyle(ThemeTokens.textSecondary)
                        .font(.subheadline.weight(.medium))

                    Stepper("\(vm.oneRMReps)", value: Binding(
                        get: { vm.oneRMReps },
                        set: { vm.oneRMReps = $0 }
                    ), in: 1...OneRMEngine.maxReliableReps)
                    .fixedSize()
                }
                .padding(.horizontal)

                if vm.oneRMReps > 10 {
                    Text("Estimates lose accuracy above 10 reps")
                        .font(.caption2)
                        .foregroundStyle(ThemeTokens.textMuted)
                        .padding(.horizontal)
                }

                // Results
                let result = vm.oneRMResult

                VStack(spacing: 12) {
                    oneRMRow(label: "Epley", value: result.epley, unit: settings.unit.symbol)
                    oneRMRow(label: "Brzycki", value: result.brzycki, unit: settings.unit.symbol)

                    Divider().opacity(0.2)

                    // Average — tap to load
                    Button {
                        vm.loadWeight(result.average.rounded())
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            vm.currentMode = .calc
                        }
                        HapticManager.shared.numpadKey()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Average (Est. 1RM)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(ThemeTokens.accentPro)
                                Text("Tap to load into CALC")
                                    .font(.caption2)
                                    .foregroundStyle(ThemeTokens.textMuted)
                            }
                            Spacer()
                            Text("\(Int(result.average.rounded())) \(settings.unit.symbol)")
                                .font(.title2.weight(.black))
                                .foregroundStyle(ThemeTokens.accentPro)
                        }
                        .padding()
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
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ThemeTokens.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        strengthRow(label: "Wilks", value: strength.wilks)
                        strengthRow(label: "DOTS", value: strength.dots)
                        strengthRow(label: "IPF GL", value: strength.ipfGL)

                        Text("IPF GL Points are calibrated for a full 3-lift total, so a single lift scores much lower than Wilks/DOTS on the same weight.")
                            .font(.caption2)
                            .foregroundStyle(ThemeTokens.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                } else {
                    Text("Set bodyweight & sex in Settings to see your strength score")
                        .font(.caption2)
                        .foregroundStyle(ThemeTokens.textMuted)
                        .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func oneRMRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ThemeTokens.textSecondary)
            Spacer()
            Text("\(Int(value.rounded())) \(unit)")
                .font(.callout.weight(.semibold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func strengthRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ThemeTokens.textSecondary)
            Spacer()
            Text("\(Int(value.rounded()))")
                .font(.callout.weight(.semibold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
        .padding(.horizontal)
    }
}
