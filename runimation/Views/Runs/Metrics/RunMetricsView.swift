import SwiftUI
import RunKit
import RunUI

struct RunMetricsView: View {

    let run: Run

    @State private var scrubProgress: Double = 0

    var body: some View {
        let seg = segment(at: scrubProgress, in: run)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RunSummaryGrid(run: run)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                chartSection("Pace", value: (seg?.speed ?? 0).formatted(.pace)) {
                    RunChart(
                        data: run.mapped(by: .pace, progress: scrubProgress),
                        progress: $scrubProgress
                    )
                }
                chartSection("Elevation", value: (seg?.elevation ?? 0).formatted(.elevation)) {
                    RunChart(
                        data: run.mapped(by: .elevation, progress: scrubProgress),
                        progress: $scrubProgress
                    )
                    .runChartKind(.filled)
                    .runChartShapeStyle(.green)
                }
                chartSection("Heart Rate", value: (seg?.heartRate ?? 0).formatted(.heartRate)) {
                    RunChart(
                        data: run.mapped(by: .heartRate, progress: scrubProgress),
                        progress: $scrubProgress
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
}
