import SwiftUI

/// A label that shows the elapsed playback time formatted as `m:ss` or `h:mm:ss`.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct ElapsedTimeLabel: View {

    @PlayerState(\.progress)
    private var progress

    @PlayerState(\.runs)
    private var runs

    @PlayerState(\.duration)
    private var duration

    var body: some View {
        Text(elapsed, format: ElapsedTimeFormatStyle())
            .font(.caption.monospacedDigit())
    }

    private var elapsed: TimeInterval {
        guard let run = runs?.run(for: .metrics) else { return 0 }
        return progress * duration(for: run.duration)
    }
}

// MARK: - Format Style

private struct ElapsedTimeFormatStyle: FormatStyle {
    func format(_ value: TimeInterval) -> String {
        let total = Int(value)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
