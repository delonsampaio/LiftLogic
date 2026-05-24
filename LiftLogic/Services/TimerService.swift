import Foundation
import Observation

@Observable
@MainActor
final class TimerService {
    enum State { case idle, running, paused, finished }

    var state: State = .idle
    var remainingSeconds: Int = 0
    var selectedPreset: Int = 120

    let presets = [90, 120, 180, 300]

    private var task: Task<Void, Never>?

    func start(seconds: Int) {
        stop()
        selectedPreset = seconds
        remainingSeconds = seconds
        state = .running
        task = Task { [weak self] in
            while let self, self.remainingSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self.remainingSeconds -= 1
            }
            if let self, !Task.isCancelled {
                self.state = .finished
                HapticManager.shared.timerComplete()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        state = .idle
        remainingSeconds = 0
    }

    func pause() {
        guard state == .running else { return }
        task?.cancel()
        task = nil
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        task = Task { [weak self] in
            while let self, self.remainingSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self.remainingSeconds -= 1
            }
            if let self, !Task.isCancelled {
                self.state = .finished
                HapticManager.shared.timerComplete()
            }
        }
    }

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
