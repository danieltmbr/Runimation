import Foundation
import RunKit

/// Maps a `Run`'s heart rate data for chart display.
///
/// Segments with a zero heart rate are excluded, as they indicate missing
/// sensor data rather than an actual reading of zero BPM.
///
/// The Y domain adds a 5 BPM margin above and below the run's HR spectrum.
///
public struct HeartRateChartMapper: RunChartMapper {

    public func value(from segment: Run.Segment) -> String {
        segment.heartRate.formatted(.heartRate)
    }

    public func map(run: Run) -> RunChart.Data {
        let origin = run.segments.first?.time.start ?? Date()
        let hrSegments = downsample(run.segments).filter { $0.heartRate > 0 }
        return RunChart.Data(
            points: hrSegments.map { .init(x: minutes(of: $0, origin: origin), y: $0.heartRate) },
            xDomain: 0...totalDurationMinutes(run),
            yDomain: (run.spectrum.heartRate.lowerBound - 5)...(run.spectrum.heartRate.upperBound + 5),
            yAxisFormatter: .heartRate
        )
    }
}

extension RunChartMapper where Self == HeartRateChartMapper {
    public static var heartRate: HeartRateChartMapper { .init() }
}

extension RunChartDataMapper where Self == HeartRateChartMapper {
    public static var heartRate: HeartRateChartMapper { .init() }
}
