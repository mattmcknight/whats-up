import AVFoundation
import AppKit

@MainActor
final class SoundPlayer {
    private nonisolated(unsafe) var loopTimer: Timer?

    func startLooping() {
        playOnce()
        loopTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playOnce()
            }
        }
    }

    func stop() {
        loopTimer?.invalidate()
        loopTimer = nil
    }

    private func playOnce() {
        NSSound(named: .init("Ping"))?.play()
    }

    deinit {
        loopTimer?.invalidate()
    }
}
