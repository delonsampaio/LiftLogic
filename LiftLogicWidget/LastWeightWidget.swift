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
            content(weightText: "\(Int(weight)) \(unit.symbol)")
                .widgetURL(URL(string: "liftlogic://calc?weight=\(weight)&unit=\(unit.rawValue)"))
        } else {
            content(weightText: "Open LiftLogic\nto get started")
        }
    }

    @ViewBuilder
    private func content(weightText: String) -> some View {
        switch family {
        case .accessoryInline:
            Text(weightText)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Last Weight")
                    .font(.caption2)
                Text(weightText)
                    .font(.headline)
            }
        default: // .systemSmall
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Weight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(weightText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
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
