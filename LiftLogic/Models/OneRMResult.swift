struct OneRMResult {
    let liftedWeight: Double
    let reps: Int                // always clamped to 1…OneRMEngine.maxReliableReps (currently 15)
    let epley: Double            // weight × (1 + reps / 30)
    let brzycki: Double          // weight × 36 / (37 − reps)
    var average: Double { (epley + brzycki) / 2 }
}
