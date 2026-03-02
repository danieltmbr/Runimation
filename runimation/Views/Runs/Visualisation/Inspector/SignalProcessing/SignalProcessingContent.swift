import SwiftUI
import RunKit
import RunUI

/// Signal processing panel: post-transformation signal preview, interpolation controls,
/// and the transformer chain manager.
///
/// Uses a single `List` with four sections:
/// - **Signal Preview** — sparkline charts with real-time playhead values + compass rose.
/// - **Interpolation** — segmented picker rendered inline (no popup, works at any detent).
/// - **Transformers** — applied chain;
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct SignalProcessingContent: View {

    var body: some View {
        List {
            previews
            interpolation
            Section {
                TransformerListButton()
            } header: {
                InspectorSectionHeader(
                    "Transformers",
                    description: "Applied sequentially to the signal. Tap ℹ to customise parameters."
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        #if os(iOS)
        .listSectionSpacing(.compact)
//        .environment(\.editMode, .constant(.active))
        #endif
    }

    // MARK: - Preview Section

    private var previews: some View {
        Section {
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
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .moveDisabled(true)
        .deleteDisabled(true)
    }

    // MARK: - Interpolation Section

    private var interpolation: some View {
        Section {
            InterpolationPicker()
                .pickerStyle(.inline)
        } header: {
            InspectorSectionHeader(
                "Interpolation",
                description: "Smooths the GPS signal between data points. Different strategies trade off responsiveness vs. smoothness."
            )
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .moveDisabled(true)
        .deleteDisabled(true)
    }

}

// MARK: - ActiveSheet

private extension SignalProcessingContent {

    enum ActiveSheet: Identifiable {
        case applied(Int)
        case catalog(RunTransformerOption)

        var id: String {
            switch self {
            case .applied(let index): return "applied-\(index)"
            case .catalog(let option): return "catalog-\(option.id.uuidString)"
            }
        }
    }
}
