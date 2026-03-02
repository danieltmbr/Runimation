import Foundation
import RunKit

/// Maps a `Run`'s elevation data for chart display.
///
/// The Y domain adds a 5 m margin above and below the run's elevation spectrum
/// so the line never sits flush against the chart edges.
///
public struct ElevationChartMapper: RunChartMapper {

    public func value(from segment: Run.Segment) -> String {
        segment.elevation.formatted(.elevation)
    }

    public func map(run: Run) -> RunChart.Data {
        let origin = run.segments.first?.time.start ?? Date()
        let sampled = downsample(run.segments)
        return RunChart.Data(
            points: sampled.map { .init(x: minutes(of: $0, origin: origin), y: $0.elevation) },
            xDomain: 0...totalDurationMinutes(run),
            yDomain: (run.spectrum.elevation.lowerBound - 5)...(run.spectrum.elevation.upperBound + 5),
            yAxisFormatter: .elevation
        )
    }
}

extension RunChartMapper where Self == ElevationChartMapper {
    public static var elevation: ElevationChartMapper { .init() }
}

extension RunChartDataMapper where Self == ElevationChartMapper {
    public static var elevation: ElevationChartMapper { .init() }
}
