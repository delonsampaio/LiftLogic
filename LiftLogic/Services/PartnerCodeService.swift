import Foundation

struct PartnerCodeService {
    private static let appIdentifier = "liftlogic"
    private static let currentVersion = 1

    static func encode(weight: Double, barType: BarType, collarType: CollarType, unit: WeightUnit, isSingleSided: Bool, customBarWeight: Double?) -> String? {
        let payload = PartnerSetupPayload(
            app: appIdentifier, version: currentVersion,
            weight: weight, barType: barType, collarType: collarType,
            unit: unit, isSingleSided: isSingleSided, customBarWeight: customBarWeight
        )
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Decodes a scanned string into a payload, returning nil for anything that isn't
    /// valid JSON, isn't a LiftLogic-authored code (wrong `app`/unsupported `version`),
    /// or carries a weight (or custom bar weight) outside the app's own input range
    /// (guards against a crafted or corrupted QR code causing a crash downstream).
    static func decode(_ string: String) -> PartnerSetupPayload? {
        guard let data = string.data(using: .utf8),
              let payload = try? JSONDecoder().decode(PartnerSetupPayload.self, from: data),
              payload.app == appIdentifier,
              payload.version == currentVersion,
              payload.weight.isFinite,
              payload.weight > 0,
              payload.weight <= (payload.unit == .lbs ? 2000 : 907),
              payload.customBarWeight.map({ $0.isFinite && $0 > 0 && $0 <= (payload.unit == .lbs ? 2000 : 907) }) ?? true
        else { return nil }
        return payload
    }
}
