struct CalculatorEngine {
    static func calculate(
        target: Double,
        barWeight: Double,
        collarWeight: Double,
        inventory: [PlateInventoryItem],
        unit: WeightUnit,
        isSingleSided: Bool
    ) -> PlateResult {
        let result = solve(target: target, barWeight: barWeight, collarWeight: collarWeight,
                           inventory: inventory, isSingleSided: isSingleSided)

        // Shortage reason policy:
        // - Exact: .none
        // - User has configured inventory (any enabled plate with a finite quantity):
        //   it's their inventory limits causing the shortfall → .outOfPlates
        // - User hasn't curated inventory (all unlimited): the target genuinely
        //   isn't loadable with available plate sizes → .unsupportedIncrement (Closest)
        let reason: ShortageReason
        if result.isExact {
            reason = .none
        } else {
            let userConfiguredInventory = inventory.contains { $0.isEnabled && $0.quantity != Int.max }
            reason = userConfiguredInventory ? .outOfPlates : .unsupportedIncrement
        }

        return PlateResult(
            platesPerSide: result.platesPerSide,
            totalWeight: target,
            remainder: result.remainder,
            shortageReason: reason
        )
    }

    /// Pure loading loop, no shortage-reason inference.
    private static func solve(
        target: Double,
        barWeight: Double,
        collarWeight: Double,
        inventory: [PlateInventoryItem],
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
            let maxPerSide = plate.quantity == Int.max
                ? Int.max
                : (isSingleSided ? plate.quantity : plate.quantity / 2)
            var used = 0
            while remaining >= plate.weight - 0.001 && used < maxPerSide && loaded.count < 11 {
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
