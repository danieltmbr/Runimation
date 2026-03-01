import Foundation
import RunKit

/// Maps a `Run`'s speed data into chart points for pace display.
///
/// Y values are stored as raw m/s speed — faster speed sits higher on a
/// standard ascending Y axis, which is the natural representation of pace
/// (faster = better = higher). The Y-axis formatter converts m/s labels to
/// the "M:SS /km" pace format.
///
/// Only segments where the runner is actively moving (speed > 1 m/s) are
/// included, removing GPS noise at standing stops.
///
public struct PaceChartMapper: RunChartMapper {

    public func map(run: Run, progress: Double) -> RunChart.Data {
        let origin = run.segments.first?.time.start ?? Date()
        let segments = movingSegments(from: run)
        return RunChart.Data(
            points: points(from: segments, origin: origin),
            xDomain: 0...totalDurationMinutes(run),
            yDomain: yDomain(for: segments, run: run),
            playheadX: playheadMinutes(progress: progress, run: run),
            yAxisFormatter: .pace
        )
    }

    // MARK: - Helpers

    /// Returns downsampled segments where the runner is actively moving.
    ///
    private func movingSegments(from run: Run) -> [Run.Segment] {
        downsample(run.segments).filter { $0.speed > 1.0 }
    }

    /// Maps each segment to a chart point with speed (m/s) as the Y value.
    ///
    private func points(from segments: [Run.Segment], origin: Date) -> [RunChart.Data.Point] {
        segments.map { segment in
            .init(
                x: minutes(of: segment, origin: origin),
                y: segment.speed
            )
        }
    }

    /// Derives the Y domain from the speed range of the supplied segments
    /// with a 5 % margin.
    ///
    private func yDomain(for segments: [Run.Segment], run: Run) -> ClosedRange<Double> {
        let speeds = segments.map(\.speed)
        let maxSpeed = speeds.max() ?? run.spectrum.speed.upperBound
        let minSpeed = max(speeds.min() ?? 1.5, 0.001)
        let margin = (maxSpeed - minSpeed) * 0.05
        return (minSpeed - margin)...(maxSpeed + margin)
    }
}

extension RunChartMapper where Self == PaceChartMapper {
    public static var pace: PaceChartMapper { .init() }
}
