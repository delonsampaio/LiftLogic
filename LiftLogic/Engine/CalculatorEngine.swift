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

        // If there's a remainder, figure out why: out of plates (quantity limits)
        // or unsupported increment (no plate small enough).
        let reason: ShortageReason
        if result.isExact {
            reason = .none
        } else {
            let unlimitedInventory = inventory.map { item in
                PlateInventoryItem(weight: item.weight, isEnabled: item.isEnabled, quantity: Int.max)
            }
            let unlimited = solve(target: target, barWeight: barWeight, collarWeight: collarWeight,
                                  inventory: unlimitedInventory, isSingleSided: isSingleSided)
            reason = unlimited.isExact ? .outOfPlates : .unsupportedIncrement
        }

        return PlateResult(
            platesPerSide: result.platesPerSide,
            totalWeight: target,
            remainder: result.remainder,
            shortageReason: reason
        )
    }

    /// Pure loading loop, no shortage-reason inference. Used twice in calculate()
    /// — once with real quantities, once with unlimited — to compare results.
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
