import SwiftUI

struct RunMetricsView: View {

    @PlayerState(\.runs)
    private var runs

    @PlayerState(\.progress)
    private var progress

    private var run: Run? { runs?.run(for: .metrics) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RunSummaryGrid()
                    if let run {
                        chartSection("Pace", unit: "min/km") {
                            RunChart(data: run.mapped(by: .pace, progress: progress))
                        }
                        chartSection("Elevation", unit: "m") {
                            RunChart(data: run.mapped(by: .elevation, progress: progress))
                                .runChartKind(.filled)
                                .runChartShapeStyle(.green)
                        }
                        chartSection("Heart Rate", unit: "bpm") {
                            RunChart(
                                data: run.mapped(by: .heartRate, progress: progress)
                            )
                            .runChartKind(.filled)
                            .runChartShapeStyle(.red)
                        }
                    }
                }
                .padding()
            }
            RunPlayerControlsView()
        }
    }

    @ViewBuilder
    private func chartSection<C: View>(
        _ title: String,
        unit: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title) (\(unit))")
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .frame(height: 150)
        }
    }
}
