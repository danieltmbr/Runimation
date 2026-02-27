import SwiftUI

/// A compact sparkline for a single run metric, shown in the diagnostics overlay.
///
/// Uses `RunChart` with any `RunChartMapper` fed from the `.diagnostics` run
/// variant, so the chart reflects actual post-transformation values. Both axes
/// are hidden by default to keep the sparkline minimal, but can be revealed via
/// `.runChartAxisVisibility()` to inspect real-world values.
///
struct DiagnosticMetricChart: View {

    @PlayerState(\.runs)
    private var runs

    @PlayerState(\.progress)
    private var progress

    let label: String

    let mapper: any RunChartMapper

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let run = runs?.run(for: .diagnostics) {
                RunChart(data: mapper.map(run: run, progress: progress))
                    .runChartPlayheadStyle(.white.opacity(0.8))
                    .runChartAxisVisibility(.none)
                    .frame(height: 50)
            }
        }
    }
}
