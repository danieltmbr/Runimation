import Charts
import SwiftUI
import RunKit

/// A thin vertical line that tracks playback progress over a `RunChart`.
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
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct RunChartPlayhead: View {

    @PlayerState(\.progress)
    private var progress

    let proxy: ChartProxy

    public init(proxy: ChartProxy) {
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
