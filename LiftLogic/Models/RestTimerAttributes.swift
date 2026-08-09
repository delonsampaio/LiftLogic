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
    /// AccentColorOption's rawValue at the moment this Live Activity started — a plain String so
    /// this shared-target file doesn't need to depend on ThemeTokens.swift, which the widget
    /// extension deliberately doesn't share. ActivityAttributes are immutable for the life of an
    /// activity, so a color change mid-timer takes effect on the *next* timer start, not live.
    var accentColorOption: String
}
