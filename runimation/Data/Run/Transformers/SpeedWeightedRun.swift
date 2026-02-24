import Foundation

/// The Speed Weighted Run processor fades direction amplitude toward zero
/// when the runner is moving slowly or stopped, and clips speed outliers
/// at the 98th percentile to prevent GPS spikes from distorting the signal.
///
struct SpeedWeightedRun: RunTransformer {

    struct Configuration {

        /// Speed in m/s at or above which direction amplitude is fully preserved.
        /// Below this threshold direction fades linearly to zero.
        ///
        let threshold: Double

        init(threshold: Double = 1.0) {
            self.threshold = threshold
        }
    }

    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    func transform(_ run: Run) -> Run {
        let segments = run.segments
        guard !segments.isEmpty else { return run }

        let sortedSpeeds = segments.map(\.speed).sorted()
        let p98Index = Int(Double(sortedSpeeds.count) * 0.98)
        let speedCap = sortedSpeeds[min(p98Index, sortedSpeeds.count - 1)]

        let threshold = configuration.threshold

        let processedSegments = segments.map { segment in
            let clampedSpeed = min(segment.speed, speedCap)
            let weight = threshold > 0 ? min(clampedSpeed / threshold, 1.0) : 1.0
            return Run.Segment(
                direction: CGPoint(
                    x: segment.direction.x * weight,
                    y: segment.direction.y * weight
                ),
                elevation: segment.elevation,
                elevationRate: segment.elevationRate,
                heartRate: segment.heartRate,
                speed: clampedSpeed,
                time: segment.time
            )
        }

        let speeds = processedSegments.map(\.speed)
        let elevations = processedSegments.map(\.elevation)
        let elevationRates = processedSegments.map(\.elevationRate)
        let nonZeroHR = processedSegments.map(\.heartRate).filter { $0 > 0 }

        let spectrum = Run.Spectrum(
            elevation: (elevations.min() ?? 0)...(elevations.max() ?? 0),
            elevationRate: (elevationRates.min() ?? 0)...(elevationRates.max() ?? 0),
            heartRate: (nonZeroHR.min() ?? 0)...(nonZeroHR.max() ?? 0),
            speed: (speeds.min() ?? 0)...(speeds.max() ?? 0),
            time: run.spectrum.time
        )

        return Run(segments: processedSegments, spectrum: spectrum)
    }
}

extension RunTransformer where Self == TransformerChain {
    
    static var speedWeighted: Self {
        self.speedWeighted(configuration: SpeedWeightedRun.Configuration())
    }
    
    static func speedWeighted(configuration: SpeedWeightedRun.Configuration) -> Self {
        TransformerChain(
            transformers: [SpeedWeightedRun(configuration: configuration)]
        )
    }
    
    var speedWeighted: Self {
        self.speedWeighted(configuration: SpeedWeightedRun.Configuration())
    }
    
    func speedWeighted(configuration: SpeedWeightedRun.Configuration) -> Self {
        self.append(transformer: .speedWeighted(configuration: configuration))
    }
}
