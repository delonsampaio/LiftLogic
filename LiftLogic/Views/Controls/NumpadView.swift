import SwiftUI

struct NumpadView: View {
    let vm: CalculatorViewModel

    private let keys: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        NumpadKeyView(key: key) {
                            if key == "⌫" {
                                vm.deleteLastDigit()
                            } else {
                                vm.appendDigit(key)
                            }
                            HapticManager.shared.numpadKey()
                        }
                    }
                }
            }
        }
    }
}

struct NumpadKeyView: View {
    let key: String
    let action: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isDelete: Bool { key == "⌫" }
    private var keyHeight: CGFloat { sizeClass == .regular ? 68 : 62 }
    private var fontSize: CGFloat { sizeClass == .regular ? 38 : 28 }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Slightly darker fill — sets the numpad below the app surface
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.10))
                // Top-edge highlight simulates elevation (lighter at top, fades out)
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                Text(key)
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDelete ? ThemeTokens.warningAmber : ThemeTokens.textPrimary)
            }
        }
        .buttonStyle(NumpadButtonStyle())
        .frame(maxWidth: .infinity)
        .frame(height: keyHeight)
        .accessibilityLabel(isDelete ? "Delete" : key == "." ? "Decimal point" : key)
    }
}

struct NumpadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
