import Foundation

extension Double {
    /// "45" for whole numbers, "2.5" for decimals.
    var weightString: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(self))
            : String(self)
    }

    /// Two-decimal precision string ("125.50") — for numpad input echo.
    var weightStringPrecise: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(self))
            : String(format: "%.2f", self)
    }
}
