import ActivityKit
import Foundation

/// Shared attributes for the Rest Timer Live Activity.
/// Used by both the main app (to start/update) and the Widget Extension (to render).
struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the timer will reach zero. Lets the Live Activity use Text(timerInterval:)
        /// for accurate countdown without us pushing updates every second.
        var endDate: Date
        var isPaused: Bool
        var pausedRemaining: Int  // seconds — only meaningful when isPaused == true
    }

    /// Total preset duration in seconds (90 / 120 / 180 / 300).
    /// Static for the life of the activity.
    var totalSeconds: Int
}
