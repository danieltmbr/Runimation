import Foundation
import CoreGraphics

/// The Guassian Run interpolator smooths the
/// run segments to avoid fequent sudden changes.
///
/// It still allows for big changes but reduces the noise
/// in the signal that could represent a qucik stop
/// at red lights in the run or GPS animalies.
///
/// The result of this smooth curve of metrics are
/// ideal to drive animations that is not too jarring
/// especially when the animation duration is short.
///
/// Smoothing uses a time-based Gaussian kernel so that
/// sigma is always in seconds, correctly handling
/// variable-duration segments (e.g. rest periods).
///
public struct GuassianRun: RunTransformer {

    public struct Configuration: Sendable {

        /// Sigma parameter for direction smoothing (seconds per axis).
        ///
        let direction: CGPoint

        /// Sigma parameter for elevation smoothing.
        ///
        let elevation: Double

        /// Sigma parameter for elevation rate smoothing.
        ///
        let elevationRate: Double

        /// Sigma parameter for heart rate smoothing.
        ///
        let heartRate: Double

        /// Sigma parameter for speed smoothing.
        ///
        let speed: Double

        public init(
            direction: CGPoint = CGPoint(x: 25, y: 25),
            elevation: Double = 10,
            elevationRate: Double = 10,
            heartRate: Double = 10,
            speed: Double = 20
        ) {
            self.direction = direction
            self.elevation = elevation
            self.elevationRate = elevationRate
            self.heartRate = heartRate
            self.speed = speed
        }
    }

    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    public func transform(_ run: Run) -> Run {
        guard !run.segments.isEmpty else { return run }
        let times = timeOffsets(from: run.segments)
        let smoothed = smooth(run.segments, times: times)
        return Run(
            segments: smoothed,
            spectrum: Run.Spectrum(from: smoothed, time: run.spectrum.time)
        )
    }

    // MARK: - Private

    private func timeOffsets(from segments: [Run.Segment]) -> [TimeInterval] {
        let start = segments[0].time.start
        return segments.map { $0.time.start.timeIntervalSince(start) }
    }

    private func smooth(_ segments: [Run.Segment], times: [TimeInterval]) -> [Run.Segment] {
        let speed = gaussianSmooth(
            segments.map(\.speed),
            times: times,
            sigma: configuration.speed
        )
        let elevation = gaussianSmooth(
            segments.map(\.elevation),
            times: times,
            sigma: configuration.elevation
        )
        let elevRate = gaussianSmooth(
            segments.map(\.elevationRate),
            times: times,
            sigma: configuration.elevationRate
        )
        let heartRate = gaussianSmooth(
            segments.map(\.heartRate),
            times: times,
            sigma: configuration.heartRate
        )
        let dirX = gaussianSmooth(
            segments.map { Double($0.direction.x) },
            times: times,
            sigma: Double(configuration.direction.x)
        )
        let dirY = gaussianSmooth(
            segments.map { Double($0.direction.y) },
            times: times,
            sigma: Double(configuration.direction.y)
        )

        return (0..<segments.count).map { i in
            Run.Segment(
                direction: CGPoint(x: dirX[i], y: dirY[i]),
                elevation: elevation[i],
                elevationRate: elevRate[i],
                heartRate: heartRate[i],
                speed: speed[i],
                time: segments[i].time
            )
        }
    }

    /// Time-based Gaussian kernel smoother.
    ///
    /// Sigma is in seconds. Each sample is weighted by its distance in time
    /// from the target, not by array index. This correctly handles
    /// variable-duration segments such as rest periods.
    ///
    private func gaussianSmooth(_ values: [Double], times: [TimeInterval], sigma: Double) -> [Double] {
        guard values.count > 1, sigma > 0 else { return values }
        let n = values.count
        var result = [Double](repeating: 0, count: n)
        let twoSigmaSq = 2.0 * sigma * sigma
        let cutoff = sigma * 3

        for i in 0..<n {
            var weightSum = 0.0
            var valueSum  = 0.0
            let ti = times[i]

            for j in i..<n {
                let dt = times[j] - ti
                if dt > cutoff { break }
                let w = exp(-(dt * dt) / twoSigmaSq)
                weightSum += w
                valueSum  += values[j] * w
            }
            for j in (0..<i).reversed() {
                let dt = ti - times[j]
                if dt > cutoff { break }
                let w = exp(-(dt * dt) / twoSigmaSq)
                weightSum += w
                valueSum  += values[j] * w
            }

            result[i] = weightSum > 0 ? valueSum / weightSum : values[i]
        }
        return result
    }
}

extension RunTransformer where Self == TransformerChain {

    public static var guassian: Self {
        self.guassian(configuration: GuassianRun.Configuration())
    }

    public static func guassian(configuration: GuassianRun.Configuration) -> Self {
        TransformerChain(transformers: [GuassianRun(configuration: configuration)])
    }

    public var guassian: Self {
        self.guassian(configuration: GuassianRun.Configuration())
    }

    public func guassian(configuration: GuassianRun.Configuration) -> Self {
        self.append(transformer: .guassian(configuration: configuration))
    }
}
