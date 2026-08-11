import Foundation

/// Decides when to prompt for an App Store review, based on successful-calculation milestones.
/// Pulled out of MainView so the threshold logic is directly unit-testable — it previously had zero
/// test coverage since it lived inline in an untested SwiftUI view.
enum AppReviewManager {
    private static let milestones: Set<Int> = [5, 20, 75]

    static func shouldRequestReview(atCount count: Int) -> Bool {
        milestones.contains(count)
    }
}
