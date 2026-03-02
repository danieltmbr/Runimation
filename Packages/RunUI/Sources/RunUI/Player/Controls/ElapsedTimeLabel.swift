import SwiftUI
import RunKit

/// A label that shows the elapsed playback time formatted as `m:ss` or `h:mm:ss`.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct ElapsedTimeLabel: View {

    @PlayerState(\.progress)
    private var progress

    @PlayerState(\.runs.metrics)
    private var run

    @PlayerState(\.duration)
    private var duration

    public init() {}

    public var body: some View {
        Text(elapsed, format: .runDuration)
            .font(.caption.monospacedDigit())
    }

    private var elapsed: TimeInterval {
        progress * duration(for: run.duration)
    }
}
