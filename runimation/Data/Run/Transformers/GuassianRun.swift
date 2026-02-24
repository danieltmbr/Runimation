import Foundation

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
struct GuassianRun: RunTransformer {

    struct Configuration {

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

        init(
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

    func transform(_ run: Run) -> Run {
        let segments = run.segments
        guard !segments.isEmpty else { return run }

        let runStart = segments[0].time.start
        let times = segments.map { $0.time.start.timeIntervalSince(runStart) }
        
        let smoothedSpeed = gaussianSmooth(
            segments.map(\.speed),
            times: times,
            sigma: configuration.speed
        )
        let smoothedElevation     = gaussianSmooth(
            segments.map(\.elevation),
            times: times,
            sigma: configuration.elevation
        )
        let smoothedElevationRate = gaussianSmooth(
            segments.map(\.elevationRate),
            times: times,
            sigma: configuration.elevationRate
        )
        let smoothedHeartRate = gaussianSmooth(
            segments.map(\.heartRate),
            times: times,
            sigma: configuration.heartRate
        )
        let smoothedDirX = gaussianSmooth(
            segments.map { Double($0.direction.x) },
            times: times,
            sigma: Double(configuration.direction.x)
        )
        let smoothedDirY = gaussianSmooth(
            segments.map { Double($0.direction.y) },
            times: times,
            sigma: Double(configuration.direction.y)
        )
        
        let smoothedSegments: [Run.Segment] = (0..<segments.count).map { i in
            Run.Segment(
                direction: CGPoint(x: smoothedDirX[i], y: smoothedDirY[i]),
                elevation: smoothedElevation[i],
                elevationRate: smoothedElevationRate[i],
                heartRate: smoothedHeartRate[i],
                speed: smoothedSpeed[i],
                time: segments[i].time
            )
        }

        let speeds = smoothedSegments.map(\.speed)
        let elevations = smoothedSegments.map(\.elevation)
        let elevationRates = smoothedSegments.map(\.elevationRate)
        let nonZeroHR = smoothedSegments.map(\.heartRate).filter { $0 > 0 }

        let spectrum = Run.Spectrum(
            elevation: (elevations.min() ?? 0)...(elevations.max() ?? 0),
            elevationRate: (elevationRates.min() ?? 0)...(elevationRates.max() ?? 0),
            heartRate: (nonZeroHR.min() ?? 0)...(nonZeroHR.max() ?? 0),
            speed: (speeds.min() ?? 0)...(speeds.max() ?? 0),
            time: run.spectrum.time
        )

        return Run(segments: smoothedSegments, spectrum: spectrum)
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
    
    static var guassian: Self {
        self.guassian(configuration: GuassianRun.Configuration())
    }
    
    static func guassian(configuration: GuassianRun.Configuration) -> Self {
        TransformerChain(transformers: [GuassianRun(configuration: configuration)])
    }
    
    var guassian: Self {
        self.guassian(configuration: GuassianRun.Configuration())
    }
    
    func guassian(configuration: GuassianRun.Configuration) -> Self {
        self.append(transformer: .guassian(configuration: configuration))
    }
}
