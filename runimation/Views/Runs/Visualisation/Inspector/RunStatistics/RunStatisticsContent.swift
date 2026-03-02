import SwiftUI
import RunKit
import RunUI
import Charts

/// Shows a full run summary and scrubbable metric charts using raw GPS data.
///
/// Section "Summary" displays aggregate statistics via `RunSummaryGrid`.
/// Section "Charts" displays scrubbable pace, elevation, and heart rate charts
/// that share a single scrub progress handle.
///
/// The scrub value labels and playheads are isolated into child views so that
/// `body` is only re-evaluated when the run data changes, not on every scrub position
/// change.
///
struct RunStatisticsContent: View {
    
    @PlayerState(\.runs.metrics)
    private var run
    
    @State
    private var scrubProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Section {
                RunSummaryGrid(run: run)
            }
            Section("Charts") {
                chartRow("Pace") {
                    ScrubValueLabel(progress: $scrubProgress, run: run) {
                        $0.speed.formatted(.pace)
                    }
                } content: {
                    RunChart(data: run.mapped(by: .pace), progress: $scrubProgress)
                        .chartOverlay { proxy in
                            ScrubChartPlayhead(progress: $scrubProgress, proxy: proxy)
                        }
                }
                chartRow("Elevation") {
                    ScrubValueLabel(progress: $scrubProgress, run: run) {
                        $0.elevation.formatted(.elevation)
                    }
                } content: {
                    RunChart(data: run.mapped(by: .elevation), progress: $scrubProgress)
                        .runChartKind(.filled)
                        .runChartShapeStyle(.green)
                        .chartOverlay { proxy in
                            ScrubChartPlayhead(progress: $scrubProgress, proxy: proxy)
                        }
                }
                chartRow("Heart Rate") {
                    ScrubValueLabel(progress: $scrubProgress, run: run) {
                        $0.heartRate.formatted(.heartRate)
                    }
                } content: {
                    RunChart(data: run.mapped(by: .heartRate), progress: $scrubProgress)
                        .runChartKind(.filled)
                        .runChartShapeStyle(.red)
                        .chartOverlay { proxy in
                            ScrubChartPlayhead(progress: $scrubProgress, proxy: proxy)
                        }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Chart Row
    
    private func chartRow<V: View, C: View>(
        _ title: String,
        @ViewBuilder value: () -> V,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                value()
                    .font(.subheadline.monospacedDigit())
            }
            content()
                .frame(height: 180)
        }
    }
}

// MARK: - Scrub Value Label

/// Reads the scrub binding independently so only this label re-renders on scrub changes,
/// not the parent chart view.
///
private struct ScrubValueLabel: View {
    
    @Binding
    var progress: Double
    
    let run: Run
    
    let format: @Sendable (Run.Segment) -> String
    
    var body: some View {
        Text(currentValue)
    }
    
    private var currentValue: String {
        let segments = run.segments
        guard !segments.isEmpty else { return "" }
        let index = min(Int(progress * Double(segments.count)), segments.count - 1)
        return format(segments[index])
    }
}
