import Charts
import SwiftUI
import RunKit

struct ChartPlayhead: View {
    
    @Environment(\.runChartPlayheadStyle)
    private var style
    
    var plotFrame: Anchor<CGRect>

    @Binding
    var progress: Double
    
    var body: some View {
        GeometryReader { geo in
            let frame = geo[plotFrame]
            Rectangle()
                .fill(style)
                .frame(width: 1.5, height: frame.height)
                .offset(x: frame.minX + frame.width * CGFloat(progress) - 0.75, y: frame.minY)
        }
    }
}


// MARK: - Environment: Playhead style

private struct RunChartPlayheadStyleKey: EnvironmentKey {
    static let defaultValue: AnyShapeStyle = AnyShapeStyle(.primary.opacity(0.5))
}

private extension EnvironmentValues {
    var runChartPlayheadStyle: AnyShapeStyle {
        get { self[RunChartPlayheadStyleKey.self] }
        set { self[RunChartPlayheadStyleKey.self] = newValue }
    }
}

extension View {
    /// Sets the colour/style of the `RunChartPlayhead` line.
    ///
    public func runChartPlayheadStyle(_ style: some ShapeStyle) -> some View {
        environment(\.runChartPlayheadStyle, AnyShapeStyle(style))
    }
}
