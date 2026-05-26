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
}
