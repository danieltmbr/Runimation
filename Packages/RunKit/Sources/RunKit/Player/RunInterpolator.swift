import Foundation
import CoreKit

/// RunInterpolator densifies a run's segments so that
/// the animation can advance at a smooth frame rate.
///
/// Implementations receive the full run and the playback
/// timing, and must return a new run with enough segments
/// to produce at least `timing.fps` updates per second
/// over `timing.duration`.
///
/// > Warning: Preserve `run.coordinates`
/// Interpolation changes temporal resolution only; it must not alter the
/// geographic path. Always construct the output run with the designated
/// initialiser, passing the input run's coordinates through: `Run(coordinates: run.coordinates, date: run.date, name: run.name, segments: interpolated, spectrum: run.spectrum)`
/// Using `Run(date:name:segments:spectrum:)` would re-derive coordinates from the
/// densified segments, producing 60× more path points and making any
/// map-rendering shader catastrophically expensive.
///
public protocol RunInterpolator: Option, Sendable {
    func interpolate(_ run: Run, timing: RunPlayer.Timing) -> Run
}

extension Run {
    public func interpolate(
        by interpolator: RunInterpolator,
        with timing: RunPlayer.Timing
    ) -> Run {
        interpolator.interpolate(self, timing: timing)
    }
}
