struct CalculatorEngine {
    static func calculate(
        target: Double,
        barWeight: Double,
        collarWeight: Double,
        inventory: [PlateInventoryItem],
        unit: WeightUnit,
        isSingleSided: Bool
    ) -> PlateResult {
        let net = max(0, target - barWeight - collarWeight)
        let perSide = isSingleSided ? net : net / 2

        let sorted = inventory
            .filter(\.isEnabled)
            .map(\.weight)
            .sorted(by: >)

        var remaining = perSide
        var loaded: [LoadedPlate] = []

        for w in sorted {
            // epsilon prevents float drift (e.g. 2.5 kg × 4 from 10.0 kg)
            while remaining >= w - 0.001 {
                loaded.append(LoadedPlate(weight: w))
                remaining -= w
            }
        }

        return PlateResult(
            platesPerSide: loaded,
            totalWeight: target,
            remainder: max(0, remaining)
        )
    }
}
