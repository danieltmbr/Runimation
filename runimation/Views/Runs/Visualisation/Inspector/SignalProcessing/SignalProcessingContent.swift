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

    @PlayerState(\.runs)
    private var runs

    @PlayerState(\.progress)
    private var progress

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
            DiagnosticMetricChart(label: "Speed", mapper: .pace, valueLabel: paceLabel)
                .runChartShapeStyle(.orange)

            DiagnosticMetricChart(label: "Heart Rate", mapper: .heartRate, valueLabel: heartRateLabel)
                .runChartShapeStyle(.red)
            
            DiagnosticMetricChart(label: "Elevation", mapper: .elevation, valueLabel: elevationLabel)
                .runChartShapeStyle(.green)
            
            VStack(alignment: .leading) {
                MetricHeader(title: "Direction", value: "")
                
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

    // MARK: - Playhead Values

    private var currentSegment: Run.Segment? {
        guard let run = runs?.run(for: .diagnostics) else { return nil }
        let segments = run.segments
        guard !segments.isEmpty else { return nil }
        let index = min(Int(progress * Double(segments.count)), segments.count - 1)
        return segments[index]
    }

    private var paceLabel: String {
        guard let speed = currentSegment?.speed else { return "" }
        return speed.formatted(.pace)
    }

    private var heartRateLabel: String {
        guard let hr = currentSegment?.heartRate, hr > 0 else { return "" }
        return hr.formatted(.heartRate)
    }

    private var elevationLabel: String {
        guard let elevation = currentSegment?.elevation else { return "" }
        return elevation.formatted(.elevation)
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
