import SwiftUI

private struct FAQItem: Identifiable {
    let id = UUID()
    let section: String
    let question: String
    let answer: String
    var isPro: Bool = false
}

struct HelpView: View {
    let isPro: Bool
    @State private var searchText = ""

    private var groupedSearchResults: [(section: String, items: [FAQItem])] {
        guard !searchText.isEmpty else { return [] }
        let matches = Self.allFAQs.filter {
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.answer.localizedCaseInsensitiveContains(searchText)
        }
        var groups: [(section: String, items: [FAQItem])] = []
        for item in matches {
            if let index = groups.firstIndex(where: { $0.section == item.section }) {
                groups[index].items.append(item)
            } else {
                groups.append((section: item.section, items: [item]))
            }
        }
        return groups
    }

    var body: some View {
        List {
            if searchText.isEmpty {
                gettingStartedSection
                platesAndBarSection
                modesSection
                gesturesSection
                proFeaturesSection
            } else if groupedSearchResults.isEmpty {
                Text("No results for \"\(searchText)\"")
                    .foregroundStyle(ThemeTokens.textMuted)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(groupedSearchResults, id: \.section) { group in
                    Section(group.section) {
                        ForEach(group.items) { item in
                            FAQRow(question: item.question, answer: item.answer, isProFeature: item.isPro, userIsPro: isPro, startExpanded: true)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Help")
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(ThemeTokens.backgroundPrimary)
    }

    // MARK: — Sections

    private var gettingStartedSection: some View {
        Section("Getting Started") {
            FAQRow(
                question: "How do I calculate my plate setup?",
                answer: "Type your total bar weight on the numpad. LiftLogic instantly calculates which plates go on each side and shows them on the barbell graphic.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What is the barbell graphic?",
                answer: "A real-time 2D visualizer showing exactly which plates are loaded on each side. Plate colors match the international standard — red for 45 lb, blue for 35 lb, yellow for 25 lb, and so on. It updates live as you type.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "How do I reset the weight?",
                answer: "Three ways: swipe the barbell left or right, double-tap it, or delete all digits on the numpad. Long-press the barbell to play a fly-off animation.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What are the recent weight chips?",
                answer: "The last 5 weights you calculated appear as chips between the − and + buttons. Tap one to reload that weight instantly. Long-press a chip to remove it.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What is the add / remove per side banner?",
                answer: "After you load a weight and then change it, a toast appears showing exactly which plates to add or remove per side. Green entries mean add, amber means remove. Tap × to dismiss it. By default it stays until dismissed — go to Settings → Calculator to turn it off or set an auto-dismiss timer with your own duration.",
                isProFeature: false, userIsPro: isPro
            )
        }
    }

    private var platesAndBarSection: some View {
        Section("Plates & Bar") {
            FAQRow(
                question: "How do I change the bar weight?",
                answer: "Tap the bar picker in the quick toggle strip below the barbell. Choose Olympic (45 lb), Women's (33 lb), EZ Curl (18 lb), Safety Squat (65 lb), or enter a custom weight.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What is Single Side mode?",
                answer: "When enabled, the calculator treats your typed weight as the total for one side only — useful for loading a landmine, single-arm attachment, or any non-symmetric setup.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What is collar weight?",
                answer: "Toggles a 2.5 lb collar deduction per side. Enable it if your gym uses locking collars that add meaningful weight to the bar.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "How do I set my plate inventory?",
                answer: "Go to Settings → Plate Inventory and enable or disable the plates your gym has. Disabled plates are skipped by the calculator. Standard plates (45 lb down to 2.5 lb) are enabled by default.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What are micro-loading (fractional) plates?",
                answer: "Ultra-small plates for tiny weight jumps — great for breaking through plateaus on bench press or overhead press. They appear in Settings → Plate Inventory as disabled by default. Toggle them on to include them in calculations. Lbs sizes: 0.25, 0.50, 0.75, 1.00, and 1.25 lb. Kg sizes: 0.25, 0.50, 1.00, 1.50, and 2.00 kg.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What are plate quantity limits?",
                answer: "In Settings → Plate Inventory, use the − button next to any enabled plate to set how many of that plate you own. The calculator will never suggest loading more plates than you have available. When you've set quantity limits and a target weight isn't reachable, the readout shows the closest achievable weight followed by \"· Out of Plates\" — the issue is your inventory, not the math. (If you haven't set any quantity limits, the readout shows the usual \"Closest\" warning instead.) In REV mode, plates at their inventory limit are dimmed and tapping them does nothing, with an amber banner above the rack.",
                isProFeature: true, userIsPro: isPro
            )
            FAQRow(
                question: "What does \"Check sleeve space\" mean?",
                answer: "An amber warning that appears below the barbell when 9 or more plates are loaded per side. Most Olympic bar sleeves hold around 8 standard plates before running out of room. Loading is capped at 11 plates per side and 2,000 lb / 907 kg total bar weight.",
                isProFeature: false, userIsPro: isPro
            )
        }
    }

    private var modesSection: some View {
        Section("Modes") {
            FAQRow(
                question: "What is CALC mode?",
                answer: "The main plate calculator. Type a total bar weight and see the exact plates to load per side, with a remainder warning if the weight isn't exactly achievable.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What is WARMUP mode?",
                answer: "Automatically generates a 5-set warmup ladder at 50%, 60%, 70%, 80%, and 90% of your target weight, rounded to loadable plates. Tap any row to load that weight into CALC.",
                isProFeature: true, userIsPro: isPro
            )
            FAQRow(
                question: "What is 1RM mode?",
                answer: "Enter a weight and rep count to estimate your one-rep max using the Epley and Brzycki formulas. The average of both is shown. Tap the result to load it into CALC. If you've set your bodyweight and sex in Settings, a Relative Strength panel below also shows your Wilks, DOTS, and IPF GL Points scores for that lift.",
                isProFeature: true, userIsPro: isPro
            )
            FAQRow(
                question: "What are Wilks, DOTS, and IPF GL Points?",
                answer: "Three real powerlifting formulas that adjust your lift for bodyweight, so you can compare relative strength across different body sizes instead of just raw numbers. They use your estimated 1RM from 1RM mode along with your bodyweight and sex (set in Settings → Pro — Bodyweight & Sex), and all three scores appear together in the 1RM mode panel.",
                isProFeature: true, userIsPro: isPro
            )
            FAQRow(
                question: "What is REV (Reverse) mode?",
                answer: "Build a bar weight by tapping plates one at a time — useful when you're standing at the rack and want to add up what's already loaded. Tap any plate on the barbell to remove it, or use the Undo button to remove the last plate added.",
                isProFeature: true, userIsPro: isPro
            )
        }
    }

    private var gesturesSection: some View {
        Section("Gestures & Controls") {
            FAQRow(
                question: "How do I clear the bar with a gesture?",
                answer: "In CALC mode: long-press the barbell to animate plates flying off, double-tap to reset instantly, or swipe left/right. In REV mode: swipe or long-press the barbell to clear all plates, or tap any individual plate on the barbell to remove it.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "What do the + and − buttons next to the weight do?",
                answer: "They increment or decrement the weight by the smallest enabled plate × 2 (one increment per side). Useful for fine-tuning without retyping the full number.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "How do I share my lift?",
                answer: "Tap the share icon in the top toolbar. LiftLogic generates a summary card showing your weight, plate breakdown, and unit — ready to share to Messages, Instagram, or anywhere.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "How do I use the rest timer?",
                answer: "Tap the timer icon in the top toolbar and pick a preset — the built-in 1:30, 2 min, 3 min, and 5 min chips, plus any named presets you've created. Add your own in Settings → Rest Timer: tap Add Preset, give it a name (e.g. \"Heavy\") and a duration, and it appears as a chip in the timer sheet. Tap a preset in Settings to edit it, or swipe to delete. The countdown appears as a Live Activity on your Lock Screen and in the Dynamic Island, and the timer icon in LiftLogic becomes a live countdown pill — tap it to reopen the controls. Three heavy haptic pulses fire at zero.",
                isProFeature: true, userIsPro: isPro
            )
        }
    }

    private var proFeaturesSection: some View {
        Section("Pro") {
            FAQRow(
                question: "What is included in Pro?",
                answer: "Warmup mode, 1RM estimator, Wilks/DOTS/IPF GL Points relative strength scoring, Reverse mode, bodyweight ratio in the readout, saved setups, rest timer, and plate quantity limits. One-time purchase, no subscription.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "How do I buy Pro?",
                answer: "Tap the PRO button in the top-right corner of the main screen, or tap any locked mode pill. The price is $0.99 — a one-time purchase with Family Sharing enabled.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "Does Pro work on all my devices?",
                answer: "Yes. Tap \"Restore Purchases\" in Settings → Pro Status to activate Pro on any iPhone signed into the same Apple ID.",
                isProFeature: false, userIsPro: isPro
            )
            FAQRow(
                question: "How do I set my bodyweight ratio?",
                answer: "Go to Settings → Pro — Bodyweight & Sex and enter your bodyweight. The ratio (e.g. \"1.87× bodyweight\") appears under the main readout and is included in your Share My Lift card. Setting your sex there also unlocks the Wilks/DOTS/IPF GL Points panel in 1RM mode.",
                isProFeature: true, userIsPro: isPro
            )
            FAQRow(
                question: "What are saved setups?",
                answer: "Bookmark any bar configuration — weight, bar type, collar, unit — for one-tap recall. Tap the bookmark icon in the top toolbar to save or load a setup.",
                isProFeature: true, userIsPro: isPro
            )
        }
    }

    // MARK: — Search index

    private static let allFAQs: [FAQItem] = [
        .init(section: "Getting Started", question: "How do I calculate my plate setup?", answer: "Type your total bar weight on the numpad. LiftLogic instantly calculates which plates go on each side and shows them on the barbell graphic."),
        .init(section: "Getting Started", question: "What is the barbell graphic?", answer: "A real-time 2D visualizer showing exactly which plates are loaded on each side. Plate colors match the international standard — red for 45 lb, blue for 35 lb, yellow for 25 lb, and so on. It updates live as you type."),
        .init(section: "Getting Started", question: "How do I reset the weight?", answer: "Three ways: swipe the barbell left or right, double-tap it, or delete all digits on the numpad. Long-press the barbell to play a fly-off animation."),
        .init(section: "Getting Started", question: "What are the recent weight chips?", answer: "The last 5 weights you calculated appear as chips between the − and + buttons. Tap one to reload that weight instantly. Long-press a chip to remove it."),
        .init(section: "Getting Started", question: "What is the add / remove per side banner?", answer: "After you load a weight and then change it, a toast appears showing exactly which plates to add or remove per side. Green entries mean add, amber means remove. Tap × to dismiss it. By default it stays until dismissed — go to Settings → Calculator to turn it off or set an auto-dismiss timer with your own duration."),
        .init(section: "Plates & Bar", question: "How do I change the bar weight?", answer: "Tap the bar picker in the quick toggle strip below the barbell. Choose Olympic (45 lb), Women's (33 lb), EZ Curl (18 lb), Safety Squat (65 lb), or enter a custom weight."),
        .init(section: "Plates & Bar", question: "What is Single Side mode?", answer: "When enabled, the calculator treats your typed weight as the total for one side only — useful for loading a landmine, single-arm attachment, or any non-symmetric setup."),
        .init(section: "Plates & Bar", question: "What is collar weight?", answer: "Toggles a 2.5 lb collar deduction per side. Enable it if your gym uses locking collars that add meaningful weight to the bar."),
        .init(section: "Plates & Bar", question: "How do I set my plate inventory?", answer: "Go to Settings → Plate Inventory and enable or disable the plates your gym has. Disabled plates are skipped by the calculator. Standard plates (45 lb down to 2.5 lb) are enabled by default."),
        .init(section: "Plates & Bar", question: "What are micro-loading (fractional) plates?", answer: "Ultra-small plates for tiny weight jumps — great for breaking through plateaus on bench press or overhead press. They appear in Settings → Plate Inventory as disabled by default. Toggle them on to include them in calculations. Lbs sizes: 0.25, 0.50, 0.75, 1.00, and 1.25 lb. Kg sizes: 0.25, 0.50, 1.00, 1.50, and 2.00 kg."),
        .init(section: "Plates & Bar", question: "What are plate quantity limits?", answer: "In Settings → Plate Inventory, use the − button next to any enabled plate to set how many of that plate you own. The calculator will never suggest loading more plates than you have available. When you've set quantity limits and a target weight isn't reachable, the readout shows the closest achievable weight followed by \"· Out of Plates\" — the issue is your inventory, not the math. (If you haven't set any quantity limits, the readout shows the usual \"Closest\" warning instead.) In REV mode, plates at their inventory limit are dimmed and tapping them does nothing, with an amber banner above the rack.", isPro: true),
        .init(section: "Plates & Bar", question: "What does \"Check sleeve space\" mean?", answer: "An amber warning that appears below the barbell when 9 or more plates are loaded per side. Most Olympic bar sleeves hold around 8 standard plates before running out of room. Loading is capped at 11 plates per side and 2,000 lb / 907 kg total bar weight."),
        .init(section: "Modes", question: "What is CALC mode?", answer: "The main plate calculator. Type a total bar weight and see the exact plates to load per side, with a remainder warning if the weight isn't exactly achievable."),
        .init(section: "Modes", question: "What is WARMUP mode?", answer: "Automatically generates a 5-set warmup ladder at 50%, 60%, 70%, 80%, and 90% of your target weight, rounded to loadable plates. Tap any row to load that weight into CALC.", isPro: true),
        .init(section: "Modes", question: "What is 1RM mode?", answer: "Enter a weight and rep count to estimate your one-rep max using the Epley and Brzycki formulas. The average of both is shown. Tap the result to load it into CALC. If you've set your bodyweight and sex in Settings, a Relative Strength panel below also shows your Wilks, DOTS, and IPF GL Points scores for that lift.", isPro: true),
        .init(section: "Modes", question: "What are Wilks, DOTS, and IPF GL Points?", answer: "Three real powerlifting formulas that adjust your lift for bodyweight, so you can compare relative strength across different body sizes instead of just raw numbers. They use your estimated 1RM from 1RM mode along with your bodyweight and sex (set in Settings → Pro — Bodyweight & Sex), and all three scores appear together in the 1RM mode panel.", isPro: true),
        .init(section: "Modes", question: "What is REV (Reverse) mode?", answer: "Build a bar weight by tapping plates one at a time — useful when you're standing at the rack and want to add up what's already loaded. Tap any plate on the barbell to remove it, or use the Undo button to remove the last plate added.", isPro: true),
        .init(section: "Gestures & Controls", question: "How do I clear the bar with a gesture?", answer: "In CALC mode: long-press the barbell to animate plates flying off, double-tap to reset instantly, or swipe left/right. In REV mode: swipe or long-press the barbell to clear all plates, or tap any individual plate on the barbell to remove it."),
        .init(section: "Gestures & Controls", question: "What do the + and − buttons next to the weight do?", answer: "They increment or decrement the weight by the smallest enabled plate × 2 (one increment per side). Useful for fine-tuning without retyping the full number."),
        .init(section: "Gestures & Controls", question: "How do I share my lift?", answer: "Tap the share icon in the top toolbar. LiftLogic generates a summary card showing your weight, plate breakdown, and unit — ready to share to Messages, Instagram, or anywhere."),
        .init(section: "Gestures & Controls", question: "How do I use the rest timer?", answer: "Tap the timer icon in the top toolbar and pick a preset — the built-in 1:30, 2 min, 3 min, and 5 min chips, plus any named presets you've created. Add your own in Settings → Rest Timer: tap Add Preset, give it a name (e.g. \"Heavy\") and a duration, and it appears as a chip in the timer sheet. Tap a preset in Settings to edit it, or swipe to delete. The countdown appears as a Live Activity on your Lock Screen and in the Dynamic Island, and the timer icon in LiftLogic becomes a live countdown pill — tap it to reopen the controls. Three heavy haptic pulses fire at zero.", isPro: true),
        .init(section: "Pro", question: "What is included in Pro?", answer: "Warmup mode, 1RM estimator, Wilks/DOTS/IPF GL Points relative strength scoring, Reverse mode, bodyweight ratio in the readout, saved setups, rest timer, and plate quantity limits. One-time purchase, no subscription."),
        .init(section: "Pro", question: "How do I buy Pro?", answer: "Tap the PRO button in the top-right corner of the main screen, or tap any locked mode pill. The price is $0.99 — a one-time purchase with Family Sharing enabled."),
        .init(section: "Pro", question: "Does Pro work on all my devices?", answer: "Yes. Tap \"Restore Purchases\" in Settings → Pro Status to activate Pro on any iPhone signed into the same Apple ID."),
        .init(section: "Pro", question: "How do I set my bodyweight ratio?", answer: "Go to Settings → Pro — Bodyweight & Sex and enter your bodyweight. The ratio (e.g. \"1.87× bodyweight\") appears under the main readout and is included in your Share My Lift card. Setting your sex there also unlocks the Wilks/DOTS/IPF GL Points panel in 1RM mode.", isPro: true),
        .init(section: "Pro", question: "What are saved setups?", answer: "Bookmark any bar configuration — weight, bar type, collar, unit — for one-tap recall. Tap the bookmark icon in the top toolbar to save or load a setup.", isPro: true),
    ]
}

private struct FAQRow: View {
    let question: String
    let answer: String
    let isProFeature: Bool
    let userIsPro: Bool
    var startExpanded: Bool = false
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(ThemeTokens.textSecondary)
                .padding(.top, 4)
        } label: {
            HStack(spacing: 6) {
                Text(question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ThemeTokens.textPrimary)
                if isProFeature && !userIsPro {
                    Text("PRO")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ThemeTokens.accentPro)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .tint(ThemeTokens.accent)
        .onAppear { if startExpanded { expanded = true } }
    }
}
