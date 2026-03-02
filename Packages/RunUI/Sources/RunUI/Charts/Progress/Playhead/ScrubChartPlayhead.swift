import Charts
import SwiftUI
import RunKit

/// Scrub-driven playhead: takes an explicit progress binding for local scrub state.
///
/// Apply via `.chartOverlay` so the line is positioned in the chart's data
/// coordinate space (accounting for any axis-label padding automatically):
///
/// ```swift
/// RunChart(data: data)
///     .chartOverlay { proxy in RunChartPlayhead(proxy: proxy) }
/// ```
///
/// Style the line with `.runChartPlayheadStyle(_:)`.
///
public struct ScrubChartPlayhead: View {

    @Binding
    var progress: Double

    let proxy: ChartProxy

    public init(progress: Binding<Double>, proxy: ChartProxy) {
        self._progress = progress
        self.proxy = proxy
    }

    public var body: some View {
        if let plotFrame = proxy.plotFrame {
            ChartPlayhead(
                plotFrame: plotFrame,
                progress: $progress
            )
        }
    }
}
