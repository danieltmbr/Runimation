import SwiftUI
import RunKit

/// A label that shows the remaining playback time formatted as `-m:ss` or `-h:mm:ss`.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct RemainingTimeLabel: View {
    
    @PlayerState(\.duration)
    private var duration

    @PlayerState(\.progress.metrics)
    private var progress
    
    @PlayerState(\.run.metrics)
    private var run

    public init() {}

    public var body: some View {
        Text(verbatim: "-\(remaining.formatted(.runDuration))")
            .monospacedDigit()
    }

    private var remaining: TimeInterval {
        (1 - progress) * duration(for: run.duration)
    }
}
