import Foundation
import Observation
import ActivityKit
import OSLog

@Observable
@MainActor
final class TimerService {
    enum State { case idle, running, paused, finished }

    var state: State = .idle
    var remainingSeconds: Int = 0
    var selectedPreset: Int = 120

    let presets = [90, 120, 180, 300]

    private var task: Task<Void, Never>?
    private var activity: Activity<RestTimerAttributes>?

    func start(seconds: Int) {
        stop()
        selectedPreset = seconds
        remainingSeconds = seconds
        state = .running
        startCountdown()
        Task { await startLiveActivity(totalSeconds: seconds) }
    }

    /// Reattaches to an existing Live Activity if one survived from a previous
    /// app launch or sheet dismiss. Called on init.
    func reattachIfNeeded() {
        guard activity == nil, let existing = Activity<RestTimerAttributes>.activities.first else { return }
        let remaining = Int(existing.content.state.endDate.timeIntervalSinceNow.rounded())
        if remaining > 0 && !existing.content.state.isPaused {
            activity = existing
            remainingSeconds = remaining
            selectedPreset = existing.attributes.totalSeconds
            state = .running
            startCountdown()
        } else if existing.content.state.isPaused {
            activity = existing
            remainingSeconds = existing.content.state.pausedRemaining
            selectedPreset = existing.attributes.totalSeconds
            state = .paused
        } else {
            // Expired — clean up
            Task {
                await existing.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// Re-syncs the in-process countdown to wall-clock time. Call when the app
    /// returns to the foreground — our background-suspended Task will be behind
    /// by however long the app was inactive.
    func syncFromActivity() {
        guard state == .running, let endDate = activity?.content.state.endDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow.rounded())
        if remaining <= 0 {
            // Should have finished while backgrounded
            task?.cancel()
            task = nil
            remainingSeconds = 0
            state = .finished
            endLiveActivity()
        } else {
            remainingSeconds = remaining
            // Restart the ticker — the previous Task is suspended/behind
            task?.cancel()
            startCountdown()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        state = .idle
        remainingSeconds = 0
        endLiveActivity()
    }

    func pause() {
        guard state == .running else { return }
        task?.cancel()
        task = nil
        state = .paused
        updateLiveActivity(paused: true)
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startCountdown()
        updateLiveActivity(paused: false)
    }

    private func startCountdown() {
        task = Task { [weak self] in
            while let self, self.remainingSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                // Re-check after sleep — syncFromActivity or another path may
                // have already taken remainingSeconds to 0 while we slept.
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                }
            }
            if let self, !Task.isCancelled {
                self.state = .finished
                HapticManager.shared.timerComplete()
                self.endLiveActivity()
                // Auto-reset to .idle after a couple seconds so the UI is ready
                // for the next timer without requiring a manual stop tap.
                try? await Task.sleep(for: .seconds(2))
                if !Task.isCancelled, self.state == .finished {
                    self.state = .idle
                    self.remainingSeconds = 0
                }
            }
        }
    }

    // MARK: — Live Activity

    private func startLiveActivity(totalSeconds: Int) async {
        // Sweep any leftover activities first — order matters: must complete
        // before we request the new one, otherwise the sweep would kill it.
        for orphan in Activity<RestTimerAttributes>.activities {
            await orphan.end(nil, dismissalPolicy: .immediate)
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.timer.info("Live Activities disabled by user")
            return
        }
        let attributes = RestTimerAttributes(totalSeconds: totalSeconds)
        let state = RestTimerAttributes.ContentState(
            endDate: Date().addingTimeInterval(TimeInterval(totalSeconds)),
            isPaused: false,
            pausedRemaining: totalSeconds
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            Logger.timer.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity(paused: Bool) {
        guard let activity else { return }
        let state = RestTimerAttributes.ContentState(
            endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
            isPaused: paused,
            pausedRemaining: remainingSeconds
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity else { return }
        let finalState = RestTimerAttributes.ContentState(
            endDate: Date(),
            isPaused: false,
            pausedRemaining: 0
        )
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }

    var formattedTime: String {
        let safe = max(0, remainingSeconds)
        let m = safe / 60
        let s = safe % 60
        return String(format: "%d:%02d", m, s)
    }
}
