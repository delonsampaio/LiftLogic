import SwiftUI

@MainActor
struct ShareService {
    static func share(vm: CalculatorViewModel, settings: AppSettings) {
        let renderer = ImageRenderer(content: ShareCardView(vm: vm, settings: settings))
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }
        let ac = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .present(ac, animated: true)
    }
}

struct ShareCardView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    private var displayWeight: Double {
        vm.currentMode == .reverse ? vm.reverseTotal : vm.targetWeight
    }

    var body: some View {
        ZStack {
            Color(white: 0.07)
            VStack(spacing: 12) {
                Text(displayWeight == 0 ? "0" : formatWeight(displayWeight))
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(settings.unit.symbol.uppercased())
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(white: 0.5))

                let grouped = vm.plateResult.grouped
                if !grouped.isEmpty {
                    let parts = grouped.map { "\($0.count)× \(formatWeight($0.weight))" }
                    Text(parts.joined(separator: " · "))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.55))
                }

                if settings.isPro, settings.bodyWeight > 0, displayWeight > 0 {
                    Text(String(format: "%.2f× bodyweight", displayWeight / settings.bodyWeight))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ThemeTokens.accentPro)
                }

                Divider().opacity(0.2).padding(.horizontal, 24)

                Text("via LiftLogic")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ThemeTokens.accent)
            }
            .padding(32)
        }
        .frame(width: 360, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : "\(value)"
    }
}
