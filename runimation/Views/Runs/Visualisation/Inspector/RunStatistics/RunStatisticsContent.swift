import SwiftUI

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
                    chartRow("Pace", unit: "min/km", value: paceString(run: run)) {
                        RunChart(
                            data: run.mapped(by: .pace, progress: scrubProgress),
                            scrubProgress: $scrubProgress
                        )
                    }
                    chartRow("Elevation", unit: "m", value: elevationString(run: run)) {
                        RunChart(
                            data: run.mapped(by: .elevation, progress: scrubProgress),
                            scrubProgress: $scrubProgress
                        )
                        .runChartKind(.filled)
                        .runChartShapeStyle(.green)
                    }
                    chartRow("Heart Rate", unit: "bpm", value: heartRateString(run: run)) {
                        RunChart(
                            data: run.mapped(by: .heartRate, progress: scrubProgress),
                            scrubProgress: $scrubProgress
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
        unit: String,
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
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
                .frame(height: 180)
        }
    }

    // MARK: - Value Formatters

    private func segment(in run: Run) -> Run.Segment? {
        let segments = run.segments
        guard !segments.isEmpty else { return nil }
        let index = min(Int(scrubProgress * Double(segments.count)), segments.count - 1)
        return segments[index]
    }

    private func paceString(run: Run) -> String {
        guard let speed = segment(in: run)?.speed, speed > 0.3 else { return "--:--" }
        let secsPerKm = 1000.0 / speed
        return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }

    private func elevationString(run: Run) -> String {
        guard let elevation = segment(in: run)?.elevation else { return "--" }
        return String(format: "%.0f", elevation)
    }

    private func heartRateString(run: Run) -> String {
        guard let hr = segment(in: run)?.heartRate, hr > 0 else { return "--" }
        return String(format: "%.0f", hr)
    }
}
