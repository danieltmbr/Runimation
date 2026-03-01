import Foundation
import RunKit

/// Maps a `Run`'s speed data into negated pace values so that faster pace
/// plots higher on a standard ascending Y axis.
///
/// Only segments where the runner is moving (speed > 1 m/s) are included,
/// which removes GPS noise at standing stops.
///
struct PaceChartMapper: RunChartMapper {

    func map(run: Run, progress: Double) -> RunChart.Data {
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

    /// Converts each segment's speed into a negated pace value (-(min/km)).
    ///
    private func points(from segments: [Run.Segment], origin: Date) -> [RunChart.Data.Point] {
        segments.map { segment in
            .init(
                x: minutes(of: segment, origin: origin),
                y: -(1000.0 / (segment.speed * 60.0))
            )
        }
    }

    /// Derives the Y domain from the speed range of the supplied segments,
    /// with a 5 % margin and a sign flip so faster pace sits higher.
    ///
    private func yDomain(for segments: [Run.Segment], run: Run) -> ClosedRange<Double> {
        let speeds = segments.map(\.speed)
        let maxSpeed = speeds.max() ?? run.spectrum.speed.upperBound
        let minSpeed = max(speeds.min() ?? 1.5, 0.001)
        let fastestPace = 1000.0 / (maxSpeed * 60.0)
        let slowestPace  = 1000.0 / (minSpeed * 60.0)
        let margin = (slowestPace - fastestPace) * 0.05
        let yFloor = -(slowestPace + margin)
        let yCeil  = -(fastestPace - margin)
        return yFloor...yCeil
    }
}

extension RunChartMapper where Self == PaceChartMapper {
    static var pace: PaceChartMapper { .init() }
}
