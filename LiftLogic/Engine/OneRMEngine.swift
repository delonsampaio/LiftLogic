struct OneRMEngine {
    static func calculate(weight: Double, reps: Int) -> OneRMResult {
        let clampedReps = min(max(reps, 1), 36)
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
