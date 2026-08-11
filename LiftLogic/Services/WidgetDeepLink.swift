import Foundation

enum WidgetDeepLink {
    /// Returns the weight and unit to load into CALC, or nil if the URL isn't a recognized deep
    /// link (wrong scheme, wrong host, missing/malformed query items, etc), the weight isn't a
    /// sane positive finite number, or the unit isn't recognized — this URL scheme is invocable
    /// by any app or Safari, not just this app's own widget, so it can't assume well-formed input.
    static func parseCalcWeight(from url: URL) -> (weight: Double, unit: WeightUnit)? {
        guard url.scheme == "liftlogic", url.host == "calc",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let weightString = components.queryItems?.first(where: { $0.name == "weight" })?.value,
              let weight = Double(weightString),
              weight.isFinite, weight > 0,
              let unitString = components.queryItems?.first(where: { $0.name == "unit" })?.value,
              let unit = WeightUnit(rawValue: unitString)
        else { return nil }
        return (weight, unit)
    }
}
