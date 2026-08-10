import Foundation

enum WidgetDeepLink {
    /// Returns the weight to load into CALC, or nil if the URL isn't a recognized deep link
    /// (wrong scheme, wrong host, missing/malformed query items, etc).
    static func parseCalcWeight(from url: URL) -> Double? {
        guard url.scheme == "liftlogic", url.host == "calc",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let weightString = components.queryItems?.first(where: { $0.name == "weight" })?.value,
              let weight = Double(weightString)
        else { return nil }
        return weight
    }
}
