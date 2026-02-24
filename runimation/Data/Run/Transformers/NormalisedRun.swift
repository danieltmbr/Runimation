import Foundation

/// The Normalised Run interpolator maps the values
/// of each run segment between a [0, 1] or [-1, 1]
/// range depending on the metric.
///
/// Speed, cadence, HR are mapped between [0, 1]
/// while direction and elevationRate are mapped to [-1, 1].
///
/// The normalisation happens based on the
/// spectrum of the input run.
///
struct NormalisedRun: RunTransformer {

    func transform(_ run: Run) -> Run {
        guard !run.segments.isEmpty else { return run }

        let spectrum = run.spectrum

        // elevationRate uses peak-absolute scaling to preserve zero = flat
        let elevRateScale = max(
            abs(spectrum.elevationRate.lowerBound),
            abs(spectrum.elevationRate.upperBound)
        )

        let normalisedSegments = run.segments.map { s in
            Run.Segment(
                direction: s.direction,
                elevation: normalise(s.elevation, in: spectrum.elevation),
                elevationRate: elevRateScale > 0 ? s.elevationRate / elevRateScale : 0,
                heartRate: normalise(s.heartRate, in: spectrum.heartRate),
                speed: normalise(s.speed, in: spectrum.speed),
                time: s.time
            )
        }

        let normalisedElevationRate: ClosedRange<Double> = elevRateScale > 0
            ? (spectrum.elevationRate.lowerBound / elevRateScale)...(spectrum.elevationRate.upperBound / elevRateScale)
            : 0...0

        let normalisedSpectrum = Run.Spectrum(
            elevation: 0...1,
            elevationRate: normalisedElevationRate,
            heartRate: 0...1,
            speed: 0...1,
            time: run.spectrum.time
        )

        return Run(segments: normalisedSegments, spectrum: normalisedSpectrum)
    }

    private func normalise(_ value: Double, in range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0.5 }
        return (value - range.lowerBound) / span
    }
}
