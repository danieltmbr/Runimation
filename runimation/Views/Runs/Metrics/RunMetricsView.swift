import SwiftUI

struct RunMetricsView: View {

    let run: Run

    @State private var scrubProgress: Double = 0

    var body: some View {
        let seg = segment(at: scrubProgress, in: run)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RunSummaryGrid(run: run)
                chartSection("Pace", unit: "min/km", value: paceString(speed: seg?.speed)) {
                    RunChart(
                        data: run.mapped(by: .pace, progress: scrubProgress),
                        scrubProgress: $scrubProgress
                    )
                }
                chartSection("Elevation", unit: "m", value: elevationString(elevation: seg?.elevation)) {
                    RunChart(
                        data: run.mapped(by: .elevation, progress: scrubProgress),
                        scrubProgress: $scrubProgress
                    )
                    .runChartKind(.filled)
                    .runChartShapeStyle(.green)
                }
                chartSection("Heart Rate", unit: "bpm", value: heartRateString(heartRate: seg?.heartRate)) {
                    RunChart(
                        data: run.mapped(by: .heartRate, progress: scrubProgress),
                        scrubProgress: $scrubProgress
                    )
                    .runChartKind(.filled)
                    .runChartShapeStyle(.red)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func chartSection<C: View>(
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
                .frame(height: 220)
        }
    }

    // MARK: - Segment lookup

    private func segment(at progress: Double, in run: Run) -> Run.Segment? {
        let segments = run.segments
        guard !segments.isEmpty else { return nil }
        let index = min(Int(progress * Double(segments.count)), segments.count - 1)
        return segments[index]
    }

    // MARK: - Value formatters

    private func paceString(speed: Double?) -> String {
        guard let speed, speed > 0.3 else { return "--:--" }
        let secsPerKm = 1000.0 / speed
        return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }

    private func elevationString(elevation: Double?) -> String {
        guard let elevation else { return "--" }
        return String(format: "%.0f", elevation)
    }

    private func heartRateString(heartRate: Double?) -> String {
        guard let heartRate, heartRate > 0 else { return "--" }
        return String(format: "%.0f", heartRate)
    }
}
