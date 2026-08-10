import Foundation

extension Double {
    /// "45" for whole numbers, "2.5" for decimals.
    var weightString: String {
        guard isFinite, abs(self) < 1e15 else { return String(format: "%.1f", self) }
        return truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(self))
            : String(self)
    }

    /// Two-decimal precision string ("125.50") — for numpad input echo.
    var weightStringPrecise: String {
        guard isFinite, abs(self) < 1e15 else { return String(format: "%.1f", self) }
        return truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(self))
            : String(format: "%.2f", self)
    }
}

/// "45s", "2m", "2:30" — shared by the rest-timer chips and preset labels.
func restTimerDurationLabel(_ seconds: Int) -> String {
    if seconds < 60 { return "\(seconds)s" }
    let m = seconds / 60
    let s = seconds % 60
    return s == 0 ? "\(m)m" : "\(m):\(String(format: "%02d", s))"
}
