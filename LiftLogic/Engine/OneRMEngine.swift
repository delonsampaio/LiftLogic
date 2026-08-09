struct OneRMEngine {
    /// Reps beyond ~12 push Epley/Brzycki past their useful range — the formulas
    /// were validated for sub-maximal sets, not endurance work.
    static let maxReliableReps = 15

    static func calculate(weight: Double, reps: Int) -> OneRMResult {
        let clampedReps = min(max(reps, 1), maxReliableReps)
        let r = Double(clampedReps)
        let epley = weight * (1 + r / 30)
        let brzycki = weight * 36 / (37 - r)
        return OneRMResult(
            liftedWeight: weight,
            reps: clampedReps,
            epley: epley,
            brzycki: brzycki
        )
    }

    /// Percent of 1RM for a given rep count at a given RPE, from the Tuchscherer/RTS chart used
    /// throughout autoregulated strength training. Returns nil when reps or rpe fall outside the
    /// chart's published range (reps 1...12, rpe 6.0...10.0 in 0.5 steps) rather than extrapolating
    /// past validated data — the chart itself stops at RPE 6 because self-assessed RPE becomes
    /// unreliable further from failure, and at 12 reps for the same kind of reliability reason
    /// Epley/Brzycki stop being trusted above `maxReliableReps`.
    static func percentOf1RM(reps: Int, rpe: Double) -> Double? {
        guard (1...12).contains(reps) else { return nil }
        let rpeKey = Int((rpe * 10).rounded())
        guard let column = rpeTable[rpeKey] else { return nil }
        return column[reps - 1]
    }

    /// Keyed by RPE × 10 (60...100 in steps of 5), not by `Double` directly — a `Double` dictionary
    /// key relies on exact floating-point equality, which is fragile in general even though the
    /// 0.5-step values used here happen to be exactly representable in IEEE 754 today. Multiplying
    /// by 10 and rounding to an `Int` key removes that dependency entirely.
    /// Each value is the 12-entry row for reps 1...12, transposed from the Tuchscherer/RTS chart's
    /// usual reps-as-rows display orientation for direct index-by-reps lookup.
    private static let rpeTable: [Int: [Double]] = [
        100: [100.0, 95.5, 92.2, 89.2, 86.3, 83.7, 81.1, 78.6, 76.2, 73.9, 71.7, 69.6],
        95:  [97.8,  93.9, 90.7, 87.8, 85.0, 82.4, 79.9, 77.4, 75.1, 72.8, 70.7, 68.6],
        90:  [95.5,  92.2, 89.2, 86.3, 83.7, 81.1, 78.6, 76.2, 73.9, 71.7, 69.6, 67.6],
        85:  [93.9,  90.7, 87.8, 85.0, 82.4, 79.9, 77.4, 75.1, 72.8, 70.7, 68.6, 66.6],
        80:  [92.2,  89.2, 86.3, 83.7, 81.1, 78.6, 76.2, 73.9, 71.7, 69.6, 67.6, 65.6],
        75:  [90.7,  87.8, 85.0, 82.4, 79.9, 77.4, 75.1, 72.8, 70.7, 68.6, 66.6, 64.7],
        70:  [89.2,  86.3, 83.7, 81.1, 78.6, 76.2, 73.9, 71.7, 69.6, 67.6, 65.6, 63.7],
        65:  [87.8,  85.0, 82.4, 79.9, 77.4, 75.1, 72.8, 70.7, 68.6, 66.6, 64.7, 62.8],
        60:  [86.3,  83.7, 81.1, 78.6, 76.2, 73.9, 71.7, 69.6, 67.6, 65.6, 63.7, 61.8],
    ]
}
