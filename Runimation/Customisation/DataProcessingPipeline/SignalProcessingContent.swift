import SwiftUI
import RunUI

/// Signal processing panel: post-transformation signal preview, interpolation controls,
/// and the transformer chain manager.
///
/// Uses a `Form` with four sections:
/// - **Interpolation** — NavigationLink row for selecting the interpolation strategy.
/// - **Pre-processing / Add** — inline expandable transformer rows with swipe-to-delete,
///   plus a catalog section to add more (rendered by `TransformersSection`).
/// - **Previews** — sparkline charts with real-time playhead values + compass rose.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct SignalProcessingContent: View {

    var body: some View {
        Form {
            Section("Interpolation") {
                InterpolationPicker()
            }
            TransformersSection()
            previews
        }
        .formStyle(.grouped)
    }

    // MARK: - Previews Section

    private var previews: some View {
        Section("Previews") {
            DiagnosticMetricChart(label: "Speed", mapper: .pace)
                .runChartShapeStyle(.orange)

            DiagnosticMetricChart(label: "Heart Rate", mapper: .heartRate)
                .runChartShapeStyle(.red)

            DiagnosticMetricChart(label: "Elevation", mapper: .elevation)
                .runChartShapeStyle(.green)

            VStack(alignment: .leading) {
                MetricHeader(title: "Direction", mapper: nil)
                CompassRose()
                    .frame(width: 100, height: 100)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
