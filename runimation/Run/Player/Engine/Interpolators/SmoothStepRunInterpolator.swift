import Foundation

/// SmoothStepRunInterpolator generates uniformly-spaced segments
/// by interpolating between the original data points using a
/// smooth-step curve instead of a linear one.
///
/// The interpolation factor `t` is passed through `smoothstep(t) = t² × (3 − 2t)`
/// before the lerp, producing an ease-in / ease-out transition between each
/// pair of GPS data points. The overall frame density and time-mapping are
/// identical to `LinearRunInterpolator`.
///
/// The spectrum is forwarded unchanged: smooth-step interpolation
/// cannot produce values outside the input range.
///
struct SmoothStepRunInterpolator: RunInterpolator {

    func interpolate(_ run: Run, timing: RunPlayer.Timing) -> Run {
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

    /// Returns the smooth-step interpolated segment at the given time offset
    /// (in seconds from the first segment's start) within the source run.
    ///
    /// Uses binary search to locate the surrounding pair, then applies
    /// `smoothstep` to the linear `t` factor before lerping all metric fields.
    /// Offsets outside the run's range are clamped.
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
        let linearT = dt > 0 ? (timeOffset - a.time.start.timeIntervalSince(origin)) / dt : 0
        let t = smoothstep(linearT)

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

    /// Applies the smooth-step curve: `t² × (3 − 2t)`.
    ///
    /// Maps [0, 1] → [0, 1] with zero first-derivative at both endpoints,
    /// giving an ease-in / ease-out transition.
    ///
    private func smoothstep(_ t: Double) -> Double {
        t * t * (3 - 2 * t)
    }
}
