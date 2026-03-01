import Foundation
import CoreGraphics

/// CatmullRomRunInterpolator generates uniformly-spaced segments using
/// the Catmull-Rom spline, which passes through every original data point
/// and produces C¹-continuous (smooth first derivative) curves between them.
///
/// Unlike linear interpolation, the spline looks ahead and behind each
/// pair of surrounding points, producing smooth acceleration and deceleration
/// rather than piecewise-linear transitions. The effect is most visible on
/// sparse input data where there is significant distance between GPS samples.
///
/// Boundary handling uses the clamped variant: the first and last segments
/// are duplicated as phantom control points, keeping the curve anchored at
/// both ends of the run.
///
/// Values may slightly overshoot the input range on sharply-changing data.
/// This does not affect animation correctness since the normalised run is
/// always re-clamped to [0, 1] by the normalisation transformer.
///
public struct CatmullRomRunInterpolator: RunInterpolator {

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
                cadence: s.cadence,
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

    /// Returns the Catmull-Rom interpolated segment at the given time offset
    /// (in seconds from the first segment's start) within the source run.
    ///
    /// Locates the two surrounding control points via binary search, then
    /// fetches the preceding and following neighbours (clamped at boundaries)
    /// and applies the spline formula to all metric fields.
    ///
    private func segment(at timeOffset: TimeInterval, in run: Run) -> Run.Segment {
        let segments = run.segments
        guard segments.count > 1 else {
            return segments.first ?? .zero
        }

        let origin = segments[0].time.start

        if timeOffset <= 0 { return segments[0] }

        let lastIndex = segments.count - 1
        let lastOffset = segments[lastIndex].time.start.timeIntervalSince(origin)
        if timeOffset >= lastOffset { return segments[lastIndex] }

        var lo = 0
        var hi = lastIndex
        while lo + 1 < hi {
            let mid = (lo + hi) / 2
            if segments[mid].time.start.timeIntervalSince(origin) <= timeOffset {
                lo = mid
            } else {
                hi = mid
            }
        }

        // P1 and P2 surround the target offset; P0 and P3 are the outer neighbours.
        let p0 = segments[max(lo - 1, 0)]
        let p1 = segments[lo]
        let p2 = segments[hi]
        let p3 = segments[min(hi + 1, lastIndex)]

        let dt = p2.time.start.timeIntervalSince(p1.time.start)
        let t = dt > 0 ? (timeOffset - p1.time.start.timeIntervalSince(origin)) / dt : 0

        return Run.Segment(
            direction: CGPoint(
                x: catmullRom(t, p0: p0.direction.x, p1: p1.direction.x, p2: p2.direction.x, p3: p3.direction.x),
                y: catmullRom(t, p0: p0.direction.y, p1: p1.direction.y, p2: p2.direction.y, p3: p3.direction.y)
            ),
            cadence:       catmullRom(t, p0: p0.cadence,       p1: p1.cadence,       p2: p2.cadence,       p3: p3.cadence),
            elevation:     catmullRom(t, p0: p0.elevation,     p1: p1.elevation,     p2: p2.elevation,     p3: p3.elevation),
            elevationRate: catmullRom(t, p0: p0.elevationRate, p1: p1.elevationRate, p2: p2.elevationRate, p3: p3.elevationRate),
            heartRate:     catmullRom(t, p0: p0.heartRate,     p1: p1.heartRate,     p2: p2.heartRate,     p3: p3.heartRate),
            speed:         catmullRom(t, p0: p0.speed,         p1: p1.speed,         p2: p2.speed,         p3: p3.speed),
            time: p1.time
        )
    }

    /// Evaluates the Catmull-Rom spline for a single scalar at parameter `t` ∈ [0, 1]
    /// between control points `p1` and `p2`, using `p0` and `p3` as outer neighbours.
    ///
    private func catmullRom(_ t: Double, p0: Double, p1: Double, p2: Double, p3: Double) -> Double {
        let t2 = t * t
        let t3 = t2 * t
        return 0.5 * (
            (2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3
        )
    }
}
