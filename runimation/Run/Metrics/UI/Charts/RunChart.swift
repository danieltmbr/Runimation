import Charts
import SwiftUI

/// A reusable chart view for displaying a single run metric over time.
///
/// Accepts pre-computed `Data` from a `RunChartMapper` and renders it with
/// configurable marks and colour. All styling is injected via environment
/// modifiers rather than init parameters, following SwiftUI conventions:
///
/// ```swift
/// RunChart(data: run.mapped(by: .pace, progress: progress))
///     .runChartKind(.filled)
///     .runChartShapeStyle(.blue)
/// ```
///
struct RunChart: View {
    
    /// Controls which chart axes are rendered.
    ///
    /// Conforms to `OptionSet` so axes can be freely combined:
    /// - `.x` — the horizontal axis and its labels.
    /// - `.y` — the vertical axis and its labels.
    /// - `.xy` — both axes (the default).
    /// - `.none`— both axes are hidden.
    ///
    struct AxisVisibility: OptionSet {
        
        let rawValue: Int
        
        /// Shows the X (horizontal) axis.
        ///
        static let x = AxisVisibility(rawValue: 1 << 0)
        
        /// Shows the Y (vertical) axis.
        ///
        static let y = AxisVisibility(rawValue: 1 << 1)
        
        /// Shows both axes.
        ///
        /// The default when no `.runChartAxisVisibility()` modifier is applied.
        ///
        static let xy: AxisVisibility = [.x, .y]
        
        /// Shows neither of the axes.
        ///
        static let none: AxisVisibility = []
    }

    /// Pure data model for a chart.
    ///
    struct Data {

        struct Point {
            
            let x: Double
            
            let y: Double
        }

        let points: [Point]
        
        let xDomain: ClosedRange<Double>
        
        let yDomain: ClosedRange<Double>

        /// X position of the playhead, in the same unit as `xDomain`.
        ///
        let playheadX: Double

        /// Formats Y-axis tick values into display strings.
        ///
        /// Accepts any `FormatStyle<Double, String>` — standard Foundation styles
        /// (e.g. `.number.precision(.fractionLength(0))`) or custom ones (e.g. `.pace`).
        ///
        let yAxisFormatter: any FormatStyle<Double, String>
    }

    /// Controls which chart marks are rendered.
    ///
    /// Conforms to `OptionSet` so styles can be freely combined:
    /// - `.line` — a line through the data points.
    /// - `.area` — a filled area below the data.
    /// - `.filled` — the common combination of both.
    ///
    /// When `.line` and `.area` are both active, the area is drawn at reduced
    /// opacity (0.2) so the line remains visually prominent.
    ///
    struct Kind: OptionSet {

        let rawValue: Int

        /// Renders a line connecting the data points.
        ///
        static let line = Kind(rawValue: 1 << 0)

        /// Renders a filled area beneath the data.
        ///
        /// When combined with `.line`, drawn at 0.2 opacity to keep the line prominent.
        ///
        static let area = Kind(rawValue: 1 << 1)

        /// A line with a subtly filled area beneath it.
        ///
        /// Convenience for `[.line, .area]`.
        ///
        static let filled: Kind = [.line, .area]
    }

    // MARK: - Properties
    
    @Environment(\.runChartKind)
    private var kind
    
    @Environment(\.runChartShapeStyle)
    private var shapeStyle
    
    @Environment(\.runChartPlayheadStyle)
    private var playheadStyle
    
    @Environment(\.runChartAxisVisibility)
    private var axisVisibility

    let data: Data

    // MARK: - Body

    var body: some View {
        if axisVisibility.contains(.x) {
            yAxisChart
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) {
                        AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)))
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .chartXAxisLabel("minutes", alignment: .trailing)
        } else {
            yAxisChart
                .chartXAxis(.hidden)
        }
    }

    // MARK: - Chart layers

    @ViewBuilder
    private var yAxisChart: some View {
        if axisVisibility.contains(.y) {
            baseChart
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        if let v = value.as(Double.self) {
                            AxisValueLabel {
                                Text(data.yAxisFormatter.format(v))
                                    .frame(width: 44, alignment: .trailing)
                            }
                        }
                        AxisGridLine()
                    }
                }
        } else {
            baseChart
                .chartYAxis(.hidden)
        }
    }

    private var baseChart: some View {
        Chart {
            if kind.contains(.area) {
                areaMarks(opacity: kind.contains(.line) ? 0.2 : 1.0)
            }
            if kind.contains(.line) {
                lineMarks
            }
            playheadMark
        }
        .chartXScale(domain: data.xDomain)
        .chartYScale(domain: data.yDomain)
    }

    // MARK: - Marks

    @ChartContentBuilder
    private func areaMarks(opacity: Double) -> some ChartContent {
        ForEach(Array(data.points.enumerated()), id: \.offset) { _, point in
            AreaMark(
                x: .value("x", point.x),
                yStart: .value("y", data.yDomain.lowerBound),
                yEnd: .value("y", point.y)
            )
            .foregroundStyle(AnyShapeStyle(shapeStyle).opacity(opacity))
        }
    }

    @ChartContentBuilder
    private var lineMarks: some ChartContent {
        ForEach(Array(data.points.enumerated()), id: \.offset) { _, point in
            LineMark(
                x: .value("x", point.x),
                y: .value("y", point.y)
            )
            .foregroundStyle(AnyShapeStyle(shapeStyle))
            .interpolationMethod(.catmullRom)
        }
    }

    private var playheadMark: some ChartContent {
        RuleMark(x: .value("Now", data.playheadX))
            .foregroundStyle(playheadStyle)
            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    }
}

// MARK: - Environment: Kind

private struct RunChartKindKey: EnvironmentKey {
    static let defaultValue: RunChart.Kind = .line
}

private extension EnvironmentValues {
    var runChartKind: RunChart.Kind {
        get { self[RunChartKindKey.self] }
        set { self[RunChartKindKey.self] = newValue }
    }
}

extension View {
    /// Sets which marks `RunChart` renders (line, area, or both).
    ///
    func runChartKind(_ kind: RunChart.Kind) -> some View {
        environment(\.runChartKind, kind)
    }
}

// MARK: - Environment: Shape style

private struct RunChartShapeStyleKey: EnvironmentKey {
    static let defaultValue: any ShapeStyle = Color.accentColor
}

private extension EnvironmentValues {
    var runChartShapeStyle: any ShapeStyle {
        get { self[RunChartShapeStyleKey.self] }
        set { self[RunChartShapeStyleKey.self] = newValue }
    }
}

extension View {
    /// Sets the colour/style applied to `RunChart`'s data marks.
    ///
    /// Defaults to `Color.accentColor`, which respects the SwiftUI `.tint()` modifier.
    ///
    func runChartShapeStyle(_ style: some ShapeStyle) -> some View {
        environment(\.runChartShapeStyle, style)
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
    /// Sets the style of `RunChart`'s playhead rule mark.
    ///
    func runChartPlayheadStyle(_ style: some ShapeStyle) -> some View {
        environment(\.runChartPlayheadStyle, AnyShapeStyle(style))
    }
}

// MARK: - Environment: Axis visibility

private struct RunChartAxisVisibilityKey: EnvironmentKey {
    static let defaultValue: RunChart.AxisVisibility = .xy
}

private extension EnvironmentValues {
    var runChartAxisVisibility: RunChart.AxisVisibility {
        get { self[RunChartAxisVisibilityKey.self] }
        set { self[RunChartAxisVisibilityKey.self] = newValue }
    }
}

extension View {
    /// Sets which axes `RunChart` renders. Defaults to `.xy` (both visible).
    ///
    func runChartAxisVisibility(_ visibility: RunChart.AxisVisibility) -> some View {
        environment(\.runChartAxisVisibility, visibility)
    }
}
