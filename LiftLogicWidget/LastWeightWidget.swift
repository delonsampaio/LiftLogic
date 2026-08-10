import WidgetKit
import SwiftUI

struct LastWeightEntry: TimelineEntry {
    let date: Date
    let weight: Double?
    let unit: WeightUnit?
}

struct LastWeightProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastWeightEntry {
        LastWeightEntry(date: Date(), weight: 225, unit: .lbs)
    }

    func getSnapshot(in context: Context, completion: @escaping (LastWeightEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastWeightEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> LastWeightEntry {
        if let last = WidgetDataStore.lastUsedWeight() {
            return LastWeightEntry(date: Date(), weight: last.weight, unit: last.unit)
        }
        return LastWeightEntry(date: Date(), weight: nil, unit: nil)
    }
}

struct LastWeightWidgetView: View {
    let entry: LastWeightEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let weight = entry.weight, let unit = entry.unit {
            content(text: "\(weight.weightStringPrecise) \(unit.symbol)", isWeight: true)
                .widgetURL(URL(string: "liftlogic://calc?weight=\(weight)&unit=\(unit.rawValue)"))
        } else {
            content(text: family == .accessoryInline ? "Open LiftLogic" : "Open LiftLogic to get started", isWeight: false)
        }
    }

    /// `isWeight` distinguishes the short, single-line weight readout (which shrinks-to-fit
    /// rather than wrapping) from the longer empty-state message (which needs to wrap, not
    /// clamp to one line). WidgetKit requires `.containerBackground(for: .widget)` to be
    /// adopted for every rendered family, including Lock Screen accessory families — the
    /// system ignores the actual color there, but the call itself is still required.
    @ViewBuilder
    private func content(text: String, isWeight: Bool) -> some View {
        switch family {
        case .accessoryInline:
            Text(text)
                .containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Last Weight")
                    .font(.caption2)
                Text(text)
                    .font(isWeight ? .headline : .caption2)
            }
            .containerBackground(for: .widget) { Color.clear }
        default: // .systemSmall
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Weight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(isWeight ? .system(size: 28, weight: .bold, design: .monospaced) : .caption)
                    .lineLimit(isWeight ? 1 : 2)
                    .minimumScaleFactor(isWeight ? 0.6 : 1.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) {
                Color("WidgetBackground")
            }
        }
    }
}

struct LastWeightWidget: Widget {
    let kind: String = "LastWeightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastWeightProvider()) { entry in
            LastWeightWidgetView(entry: entry)
        }
        .configurationDisplayName("Last Weight")
        .description("Shows the last weight you calculated in LiftLogic.")
        .supportedFamilies([.systemSmall, .accessoryInline, .accessoryRectangular])
    }
}
