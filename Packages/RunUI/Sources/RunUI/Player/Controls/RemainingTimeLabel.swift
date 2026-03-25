import SwiftUI
import RunKit

/// A label that shows the remaining playback time formatted as `-m:ss` or `-h:mm:ss`.
///
/// When a progress is passed in through the initialiser with a non-nil value,
/// the label displays the remaining time for the given progress.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct RemainingTimeLabel: View {
    
    private var displayProgress: TimeInterval {
        progress?.clamped(0, 1) ?? playerProgress
    }
    
    @PlayerState(\.duration)
    private var duration

    @PlayerState(\.progress.metrics)
    private var playerProgress
    
    private var progress: TimeInterval?

    @PlayerState(\.run.metrics)
    private var run

    public init(progress: TimeInterval? = nil) {
        self.progress = progress
    }

    public var body: some View {
        Text(verbatim: "-\(remaining.formatted(.runDuration))")
            .font(.caption.monospacedDigit())
    }

    private var remaining: TimeInterval {
        (1 - displayProgress) * duration(for: run.duration)
    }
}
