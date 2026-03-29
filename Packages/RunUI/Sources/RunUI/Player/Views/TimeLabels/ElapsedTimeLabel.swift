import SwiftUI
import RunKit

/// A label that shows the elapsed playback time formatted as `m:ss` or `h:mm:ss`.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct ElapsedTimeLabel: View {
    
    @PlayerState(\.duration)
    private var duration

    @PlayerState(\.progress.metrics)
    private var progress

    public init() {}

    public var body: some View {
        Text(elapsed, format: .runDuration)
            .monospacedDigit()
    }

    private var elapsed: TimeInterval {
        progress * duration
    }
}
