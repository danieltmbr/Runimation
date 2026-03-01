import Foundation

/// LinearRunInterpolator generates uniformly-spaced segments
/// by linearly interpolating between the original data points.
///
/// The output contains exactly `ceil(timing.fps * timing.duration)`
/// frames, each covering an equal slice of the run's real-time
/// duration. Values are computed via binary search into the
/// original segments followed by lerp on all metric fields.
///
/// The spectrum is forwarded unchanged: linear interpolation
/// cannot produce values outside the input range.
///
public struct LinearRunInterpolator: RunInterpolator {

    public func interpolate(_ run: Run, timing: RunPlayer.Timing) -> Run {
        guard !run.segments.isEmpty, timing.fps > 0, timing.duration > 0 else {
            return run
        }

        let totalFrames = Int(ceil(timing.fps * timing.duration))
        guard totalFrames > 0 else { return run }

        let runDuration = run.duration
        guard runDuration > 0 else { return run }

        let timeStep = runDuration / Double(totalFrames)
        let startDate = run.segments[0].time.start

        let segments: [Run.Segment] = (0..<totalFrames).map { i in
            let t = Double(i) * timeStep
            let start = startDate.addingTimeInterval(t)
            let end = startDate.addingTimeInterval(t + timeStep)
            let s = segment(at: t, in: run)
            return Run.Segment(
                direction: s.direction,
                elevation: s.elevation,
                elevationRate: s.elevationRate,
                heartRate: s.heartRate,
                speed: s.speed,
                time: DateInterval(start: start, end: end)
            )
        }

        return Run(segments: segments, spectrum: run.spectrum)
    }

    // MARK: - Private

    /// Returns the linearly interpolated segment at the given time offset
    /// (in seconds from the first segment's start) within the source run.
    ///
    /// Uses binary search to locate the surrounding pair, then lerps all
    /// metric fields. Offsets outside the run's range are clamped.
    ///
    private func segment(at timeOffset: TimeInterval, in run: Run) -> Run.Segment {
        let segments = run.segments
        guard segments.count > 1 else {
            return segments.first ?? .zero
        }

        let origin = segments[0].time.start

        if timeOffset <= 0 { return segments[0] }

        let lastOffset = segments.last!.time.start.timeIntervalSince(origin)
        if timeOffset >= lastOffset { return segments.last! }

        var lo = 0
        var hi = segments.count - 1
        while lo + 1 < hi {
            let mid = (lo + hi) / 2
            if segments[mid].time.start.timeIntervalSince(origin) <= timeOffset {
                lo = mid
            } else {
                hi = mid
            }
        }

        let a = segments[lo]
        let b = segments[hi]
        let dt = b.time.start.timeIntervalSince(a.time.start)
        let t = dt > 0 ? (timeOffset - a.time.start.timeIntervalSince(origin)) / dt : 0

        return Run.Segment(
            direction: CGPoint(
                x: a.direction.x + (b.direction.x - a.direction.x) * t,
                y: a.direction.y + (b.direction.y - a.direction.y) * t
            ),
            elevation: a.elevation + (b.elevation - a.elevation) * t,
            elevationRate: a.elevationRate + (b.elevationRate - a.elevationRate) * t,
            heartRate: a.heartRate + (b.heartRate - a.heartRate) * t,
            speed: a.speed + (b.speed - a.speed) * t,
            time: a.time
        )
    }
}
