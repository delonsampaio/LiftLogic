import SwiftUI

struct EmptyStateView: View {
    @State private var arrowOffset: CGFloat = 0

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.7 : 1.0 }

    var body: some View {
        VStack(spacing: 6 * scale) {
            Image(systemName: "chevron.down")
                .font(.system(size: 16 * scale, weight: .light))
                .foregroundStyle(ThemeTokens.textMuted)
                .offset(y: arrowOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        arrowOffset = 7
                    }
                }
            Text("Type a weight to get started")
                .font(.system(size: 13 * scale))
                .foregroundStyle(ThemeTokens.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6 * scale)
    }
}
