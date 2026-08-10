import Foundation

enum WidgetDeepLink {
    /// Returns the weight to load into CALC, or nil if the URL isn't a recognized deep link
    /// (wrong scheme, wrong host, missing/malformed query items, etc) or the weight isn't a
    /// sane positive finite number — this URL scheme is invocable by any app or Safari, not
    /// just this app's own widget, so it can't assume well-formed input.
    static func parseCalcWeight(from url: URL) -> Double? {
        guard url.scheme == "liftlogic", url.host == "calc",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let weightString = components.queryItems?.first(where: { $0.name == "weight" })?.value,
              let weight = Double(weightString),
              weight.isFinite, weight > 0
        else { return nil }
        return weight
    }
}
