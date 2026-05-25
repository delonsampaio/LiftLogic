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
            .sorted { $0.weight > $1.weight }

        var remaining = perSide
        var loaded: [LoadedPlate] = []

        for plate in sorted {
            // Quantity is stored as total plates owned; divide by 2 for each side (two-sided loading)
            let maxPerSide = plate.quantity == Int.max
                ? Int.max
                : (isSingleSided ? plate.quantity : plate.quantity / 2)
            var used = 0
            while remaining >= plate.weight - 0.001 && used < maxPerSide {
                loaded.append(LoadedPlate(weight: plate.weight))
                remaining -= plate.weight
                used += 1
            }
        }

        return PlateResult(
            platesPerSide: loaded,
            totalWeight: target,
            remainder: max(0, remaining)
        )
    }
}
