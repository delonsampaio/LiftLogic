struct WarmupSet: Identifiable {
    var id: Int { percentage }
    let percentage: Int          // 50, 60, 70, 80, or 90
    let targetWeight: Double
    let platesPerSide: [LoadedPlate]
}
