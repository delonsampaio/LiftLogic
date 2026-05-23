struct WarmupEngine {
    static let percentages = [50, 60, 70, 80, 90]

    static func calculate(
        target: Double,
        barWeight: Double,
        collarWeight: Double,
        inventory: [PlateInventoryItem],
        unit: WeightUnit,
        isSingleSided: Bool
    ) -> [WarmupSet] {
        percentages.map { pct in
            let targetForPct = (target * Double(pct) / 100).rounded()
            let result = CalculatorEngine.calculate(
                target: targetForPct,
                barWeight: barWeight,
                collarWeight: collarWeight,
                inventory: inventory,
                unit: unit,
                isSingleSided: isSingleSided
            )
            return WarmupSet(
                percentage: pct,
                targetWeight: targetForPct,
                platesPerSide: result.platesPerSide
            )
        }
    }
}
