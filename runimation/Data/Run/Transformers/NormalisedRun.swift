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
        let scale = elevationRateScale(for: run.spectrum)
        let normalised = normalise(run.segments, using: run.spectrum, elevationRateScale: scale)
        let spectrum = normalisedSpectrum(from: run.spectrum, elevationRateScale: scale)
        return Run(segments: normalised, spectrum: spectrum)
    }

    // MARK: - Private

    private func elevationRateScale(for spectrum: Run.Spectrum) -> Double {
        max(abs(spectrum.elevationRate.lowerBound), abs(spectrum.elevationRate.upperBound))
    }

    private func normalise(
        _ segments: [Run.Segment],
        using spectrum: Run.Spectrum,
        elevationRateScale scale: Double
    ) -> [Run.Segment] {
        segments.map { s in
            Run.Segment(
                direction: s.direction,
                elevation: normalise(s.elevation, in: spectrum.elevation),
                elevationRate: scale > 0 ? s.elevationRate / scale : 0,
                heartRate: normalise(s.heartRate, in: spectrum.heartRate),
                speed: normalise(s.speed, in: spectrum.speed),
                time: s.time
            )
        }
    }

    /// Builds a fully normalised spectrum for the output run.
    /// elevationRate preserves its asymmetric range rather than clamping to [-1, 1],
    /// reflecting the actual peak in each direction.
    ///
    private func normalisedSpectrum(from spectrum: Run.Spectrum, elevationRateScale scale: Double) -> Run.Spectrum {
        let elevationRate: ClosedRange<Double> = scale > 0
            ? (spectrum.elevationRate.lowerBound / scale)...(spectrum.elevationRate.upperBound / scale)
            : 0...0
        return Run.Spectrum(
            elevation: 0...1,
            elevationRate: elevationRate,
            heartRate: 0...1,
            speed: 0...1,
            time: spectrum.time
        )
    }

    private func normalise(_ value: Double, in range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0.5 }
        return (value - range.lowerBound) / span
    }
}

extension RunTransformer where Self == TransformerChain {

    static var normalised: Self {
        TransformerChain(transformers: [NormalisedRun()])
    }

    var normalised: Self {
        self.append(transformer: .normalised)
    }
}
