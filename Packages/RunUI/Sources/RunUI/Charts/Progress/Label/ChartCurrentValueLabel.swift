import SwiftUI
import RunKit

// MARK: - Current Segment Value

/// Reads `progress` independently so only this label re-renders on each playback tick,
/// not the parent chart view.
///
public struct ChartCurrentValueLabel: View {
    
    @PlayerState(\.segment.diagnostics)
    private var segment
    
    let mapper: any RunChartValueMapper
    
    public init(mapper: any RunChartValueMapper) {
        self.mapper = mapper
    }
    
    public var body: some View {
        Text(mapper.value(from: segment))
    }
}
