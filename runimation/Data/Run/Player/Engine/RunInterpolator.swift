import Foundation

/// RunInterpolator densifies a run's segments so that
/// the animation can advance at a smooth frame rate.
///
/// Implementations receive the full run and the playback
/// timing, and must return a new run with enough segments
/// to produce at least `timing.fps` updates per second
/// over `timing.duration`.
///
protocol RunInterpolator {
    func interpolate(_ run: Run, timing: RunPlayer.Timing) -> Run
}

extension Run {
    func interpolate(
        by interpolator: RunInterpolator,
        with timing: RunPlayer.Timing
    ) -> Run {
        interpolator.interpolate(self, timing: timing)
    }
}
