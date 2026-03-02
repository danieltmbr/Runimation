import SwiftUI
import RunKit
import RunUI
import Charts

/// A compact sparkline for a single run metric, shown in the diagnostics overlay.
///
/// Uses `RunChart` with any `RunChartMapper` fed from the `.diagnostics` run
/// variant, so the chart reflects actual post-transformation values. Both axes
/// are hidden by default to keep the sparkline minimal, but can be revealed via
/// `.runChartAxisVisibility()` to inspect real-world values.
///
/// The value label is rendered by an isolated child view that reads `progress`
/// independently, so the chart is only re-rendered when the run data changes —
/// not on every playback tick.
///
struct DiagnosticMetricChart: View {

    @PlayerState(\.runs.diagnostics)
    private var run

    let label: String

    let mapper: any RunChartMapper

    var body: some View {
        VStack(alignment: .leading) {
            MetricHeader(title: label, mapper: mapper)
            RunChart(data: mapper.map(run: run))
                .runChartPlayheadStyle(Color.accentColor.opacity(0.8))
                .runChartAxisVisibility(.none)
                .chartOverlay { proxy in RunChartPlayhead(proxy: proxy) }
                .frame(height: 70)
        }
    }
}
