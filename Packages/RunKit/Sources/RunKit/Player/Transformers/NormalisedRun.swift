import Foundation
import CoreGraphics

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
public struct NormalisedRun: RunTransformer {

    public let label = "Normalised"

    public let description = "Maps metrics to [0, 1] or [-1, 1] ranges based on the run's own spectrum."

    public func transform(_ run: Run) -> Run {
        guard !run.segments.isEmpty else { return run }
        let scale = elevationRateScale(for: run.spectrum)
        let normalised = normalise(run.segments, using: run.spectrum, elevationRateScale: scale)
        let spectrum = normalisedSpectrum(from: run.spectrum, elevationRateScale: scale, normalised: normalised)
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
        let bounds = spectrum.coordinateBounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let cosLat = cos(center.y * .pi / 180.0)
        let halfSpan = max(bounds.width * cosLat, bounds.height) / 2.0
        return segments.map { s in
            Run.Segment(
                cadence: normalise(s.cadence, in: spectrum.cadence),
                coordinate: normaliseCoordinate(s.coordinate, center: center, cosLat: cosLat, halfSpan: halfSpan),
                direction: s.direction,
                elevation: normalise(s.elevation, in: spectrum.elevation),
                elevationRate: scale > 0 ? s.elevationRate / scale : 0,
                heartRate: normalise(s.heartRate, in: spectrum.heartRate),
                speed: normalise(s.speed, in: spectrum.speed),
                time: s.time
            )
        }
    }

    /// Maps a raw lat/lon coordinate to the normalised plane, preserving aspect ratio.
    ///
    /// Applies the equirectangular correction to the longitude axis (`cosLat`) so that
    /// one unit on x equals the same physical distance as one unit on y.
    /// The longer geographic axis maps to [-1, 1]; the shorter axis maps within that range.
    ///
    private func normaliseCoordinate(
        _ coordinate: CGPoint,
        center: CGPoint,
        cosLat: Double,
        halfSpan: Double
    ) -> CGPoint {
        guard halfSpan > 0 else { return .zero }
        return CGPoint(
            x: (coordinate.x - center.x) * cosLat / halfSpan,
            y: (coordinate.y - center.y) / halfSpan
        )
    }

    /// Builds a fully normalised spectrum for the output run.
    /// elevationRate preserves its asymmetric range rather than clamping to [-1, 1],
    /// reflecting the actual peak in each direction.
    /// coordinateBounds reflects the actual normalised extent, which may be narrower
    /// than [-1, 1] on the shorter axis due to aspect-ratio preservation.
    ///
    private func normalisedSpectrum(
        from spectrum: Run.Spectrum,
        elevationRateScale scale: Double,
        normalised: [Run.Segment]
    ) -> Run.Spectrum {
        let elevationRate: ClosedRange<Double> = scale > 0
            ? (spectrum.elevationRate.lowerBound / scale)...(spectrum.elevationRate.upperBound / scale)
            : 0...0
        let xs = normalised.map(\.coordinate.x)
        let ys = normalised.map(\.coordinate.y)
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 0
        return Run.Spectrum(
            cadence: 0...1,
            coordinateBounds: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
            distance: spectrum.distance,
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

extension RunTransformer where Self == NormalisedRun {
    
    public static var normalised: Self {
        NormalisedRun()
    }
}
