import Foundation

/// Centralizes the "is this Pro-gated feature actually available" check. A pure predicate, not a
/// control-flow helper: callers still own presenting their own paywall UI on `false`.
enum ProGate {
    static func isAllowed(requiresPro: Bool, isPro: Bool) -> Bool {
        !requiresPro || isPro
    }
}
