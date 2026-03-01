import SwiftUI
import RunKit
import RunUI

/// Shows a full run summary and scrubbable metric charts using raw GPS data.
///
/// Section "Summary" displays aggregate statistics via `RunSummaryGrid`.
/// Section "Charts" displays scrubbable pace, elevation, and heart rate charts
/// that share a single scrub progress handle.
///
struct RunStatisticsContent: View {

    @PlayerState(\.runs)
    private var runs

    @State
    private var scrubProgress: Double = 0

    var body: some View {
        if let run = runs?.run(for: .metrics) {
            VStack(alignment: .leading, spacing: 24) {
                Section {
                    RunSummaryGrid(run: run)
                }
                Section("Charts") {
                    chartRow("Pace", value: currentSegment(in: run)?.speed.formatted(.pace) ?? "--:-- /km") {
                        RunChart(
                            data: run.mapped(by: .pace, progress: scrubProgress),
                            progress: $scrubProgress
                        )
                    }
                    chartRow("Elevation", value: currentSegment(in: run)?.elevation.formatted(.elevation) ?? "-- m") {
                        RunChart(
                            data: run.mapped(by: .elevation, progress: scrubProgress),
                            progress: $scrubProgress
                        )
                        .runChartKind(.filled)
                        .runChartShapeStyle(.green)
                    }
                    chartRow("Heart Rate", value: currentSegment(in: run)?.heartRate.formatted(.heartRate) ?? "-- bpm") {
                        RunChart(
                            data: run.mapped(by: .heartRate, progress: scrubProgress),
                            progress: $scrubProgress
                        )
                        .runChartKind(.filled)
                        .runChartShapeStyle(.red)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Chart Row

    private func chartRow<C: View>(
        _ title: String,
        value: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(value)
                    .font(.subheadline.monospacedDigit())
            }
            content()
                .frame(height: 180)
        }
    }

    // MARK: - Segment lookup

    private func currentSegment(in run: Run) -> Run.Segment? {
        let segments = run.segments
        guard !segments.isEmpty else { return nil }
        let index = min(Int(scrubProgress * Double(segments.count)), segments.count - 1)
        return segments[index]
    }
}
