import SwiftUI

struct RestTimerView: View {
    let timer: TimerService
    let settings: AppSettings
    @Binding var isPresented: Bool

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 2.2 : 1.0 }

    var body: some View {
        VStack(spacing: 20 * scale) {
            // Timer display — idle label uses a smaller wordmark-style font;
            // the running countdown gets the large monospaced digit treatment.
            Group {
                if timer.state == .idle {
                    Text("Rest Timer")
                        .font(sizeClass == .regular ? .title.weight(.black) : .title2.weight(.black))
                } else {
                    Text(timer.formattedTime)
                        .font(.system(size: 48 * scale, weight: .black, design: .monospaced))
                }
            }
            .foregroundStyle(timer.state == .finished ? settings.accentColor : ThemeTokens.textPrimary)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3), value: timer.remainingSeconds)

            // Preset chips — built-ins first, then the user's named presets.
            // Wraps to additional rows so every preset is visible without scrolling.
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(timer.presets, id: \.self) { seconds in
                    presetChip(seconds: seconds, label: formatPreset(seconds), name: nil)
                }
                ForEach(settings.restTimerPresets) { preset in
                    presetChip(seconds: preset.seconds, label: preset.name, name: preset.name)
                }
            }

            // Controls
            HStack(spacing: 16 * scale) {
                if timer.state == .running {
                    Button {
                        timer.pause()
                    } label: {
                        controlButton(systemImage: "pause.fill", color: ThemeTokens.textSecondary)
                    }
                } else if timer.state == .paused {
                    Button {
                        timer.resume()
                    } label: {
                        controlButton(systemImage: "play.fill", color: settings.accentColor)
                    }
                }

                if timer.state != .idle {
                    Button {
                        timer.stop()
                    } label: {
                        controlButton(systemImage: "stop.fill", color: ThemeTokens.textMuted)
                    }
                }
            }

            Button("Dismiss") { isPresented = false }
                .font(sizeClass == .regular ? .subheadline : .footnote)
                .foregroundStyle(ThemeTokens.textMuted)
        }
        .padding(16 * scale)
        .background(ThemeTokens.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    @ViewBuilder
    private func presetChip(seconds: Int, label: String, name: String?) -> some View {
        let isActive = timer.state != .idle && timer.selectedPreset == seconds && seconds > 0
        Button {
            timer.start(seconds: seconds, accentColorOption: settings.accentColorOption.rawValue)
        } label: {
            Text(label)
                .font(sizeClass == .regular ? .title3.weight(.semibold) : .footnote.weight(.semibold))
                .foregroundStyle(isActive ? settings.accentColor : ThemeTokens.textMuted)
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 8 * scale)
                .background(
                    Capsule()
                        .fill(isActive ? settings.accentColor.opacity(0.15) : Color(white: 0.12))
                        .overlay(Capsule().strokeBorder(
                            isActive ? settings.accentColor.opacity(0.4) : Color(white: 0.2),
                            lineWidth: 1
                        ))
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func controlButton(systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 22 * scale))
            .foregroundStyle(color)
            .frame(width: 52 * scale, height: 52 * scale)
            .background(Circle().fill(Color(white: 0.15)))
    }

    private func formatPreset(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m):\(String(format: "%02d", s))"
    }
}

/// Left-to-right, top-to-bottom wrapping layout, each row centered within the
/// available width. Used so rest-timer preset chips are all visible at once
/// instead of requiring horizontal scroll.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    private struct Row {
        var range: Range<Int>
        var width: CGFloat
        var height: CGFloat
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var start = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let addedWidth = size.width + (index > start ? spacing : 0)
            if rowWidth + addedWidth > maxWidth, index > start {
                rows.append(Row(range: start..<index, width: rowWidth, height: rowHeight))
                start = index
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += addedWidth
                rowHeight = max(rowHeight, size.height)
            }
        }
        if start < subviews.count {
            rows.append(Row(range: start..<subviews.count, width: rowWidth, height: rowHeight))
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let contentWidth = rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * rowSpacing
        let width = proposal.width ?? contentWidth
        return CGSize(width: width.isFinite ? width : contentWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX + max(0, (bounds.width - row.width) / 2)
            for index in row.range {
                let subview = subviews[index]
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }
}
