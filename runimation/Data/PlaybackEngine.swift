import SwiftUI

enum PlaybackPreset: String, CaseIterable, Identifiable {
    case fifteenSeconds = "15s"
    case thirtySeconds = "30s"
    case oneMinute = "1 min"
    case realTime = "Real-time"

    var id: String { rawValue }

    func targetDuration(forRunDuration runDuration: TimeInterval) -> TimeInterval {
        switch self {
        case .fifteenSeconds: return 15.0
        case .thirtySeconds: return 30.0
        case .oneMinute: return 60.0
        case .realTime: return runDuration
        }
    }
}

@Observable
final class PlaybackEngine {

    let runData: RunData

    // Playback state
    var preset: PlaybackPreset = .thirtySeconds {
        didSet { reset() }
    }
    var isPlaying = false
    var progress: Double = 0.0 // 0...1

    // Shader-ready interpolated values
    private(set) var currentSpeed: Float = 0
    private(set) var currentElevation: Float = 0.5
    private(set) var currentHeartRate: Float = 0.5
    private(set) var currentDirX: Float = 0
    private(set) var currentDirY: Float = 0
    private(set) var currentTime: Float = 0

    // For delta-time computation
    private var lastDate: Date?

    init(runData: RunData) {
        self.runData = runData
        // Initialize with first sample values
        let initial = runData.interpolated(at: 0)
        currentSpeed = initial.speed
        currentElevation = initial.elevation
        currentHeartRate = initial.heartRate
        currentDirX = initial.dirX
        currentDirY = initial.dirY
    }

    // MARK: - Controls

    func play() {
        if progress >= 1.0 { reset() }
        isPlaying = true
        lastDate = nil
    }

    func pause() {
        isPlaying = false
        lastDate = nil
    }

    func reset() {
        isPlaying = false
        progress = 0
        currentTime = 0
        lastDate = nil
        updateSampleValues()
    }

    func seek(to progress: Double) {
        guard preset == .realTime else { return }
        self.progress = max(0, min(progress, 1.0))
        updateSampleValues()
    }

    /// Called every frame from TimelineView. Computes dt and advances playback.
    func update(now: Date) {
        guard isPlaying else {
            lastDate = now
            return
        }

        let dt: TimeInterval
        if let last = lastDate {
            dt = min(now.timeIntervalSince(last), 0.1) // cap at 100ms to avoid jumps
        } else {
            dt = 0
        }
        lastDate = now

        let targetDuration = preset.targetDuration(forRunDuration: runData.totalDuration)
        guard targetDuration > 0 else { return }

        progress = min(1.0, progress + dt / targetDuration)
        currentTime += Float(dt)

        updateSampleValues()

        if progress >= 1.0 {
            isPlaying = false
        }
    }

    // MARK: - Private

    private func updateSampleValues() {
        let runTimeOffset = progress * runData.totalDuration
        let sample = runData.interpolated(at: runTimeOffset)
        currentSpeed = sample.speed
        currentElevation = sample.elevation
        currentHeartRate = sample.heartRate
        currentDirX = sample.dirX
        currentDirY = sample.dirY
    }
}
