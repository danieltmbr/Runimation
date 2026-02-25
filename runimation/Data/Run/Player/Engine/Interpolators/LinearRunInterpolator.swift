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
struct LinearRunInterpolator: RunInterpolator {

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
            let s = run.segment(at: t)
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
}
