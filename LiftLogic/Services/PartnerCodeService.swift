import Foundation

struct PartnerCodeService {
    private static let appIdentifier = "liftlogic"
    private static let currentVersion = 1

    static func encode(weight: Double, barType: BarType, collarType: CollarType, unit: WeightUnit, isSingleSided: Bool) -> String? {
        let payload = PartnerSetupPayload(
            app: appIdentifier, version: currentVersion,
            weight: weight, barType: barType, collarType: collarType,
            unit: unit, isSingleSided: isSingleSided
        )
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Decodes a scanned string into a payload, returning nil for anything that isn't
    /// valid JSON or isn't a LiftLogic-authored code (wrong `app`/unsupported `version`).
    static func decode(_ string: String) -> PartnerSetupPayload? {
        guard let data = string.data(using: .utf8),
              let payload = try? JSONDecoder().decode(PartnerSetupPayload.self, from: data),
              payload.app == appIdentifier,
              payload.version == currentVersion else { return nil }
        return payload
    }
}
