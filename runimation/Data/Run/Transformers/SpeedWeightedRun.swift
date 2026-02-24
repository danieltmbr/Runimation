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
        guard !run.segments.isEmpty else { return run }
        let cap = speedCap(from: run.segments)
        let weighted = weightedSegments(from: run.segments, cap: cap)
        return Run(
            segments: weighted,
            spectrum: Run.Spectrum(from: weighted, time: run.spectrum.time)
        )
    }

    // MARK: - Private

    private func speedCap(from segments: [Run.Segment]) -> Double {
        let sorted = segments.map(\.speed).sorted()
        let p98Index = Int(Double(sorted.count) * 0.98)
        return sorted[min(p98Index, sorted.count - 1)]
    }

    private func weightedSegments(from segments: [Run.Segment], cap: Double) -> [Run.Segment] {
        segments.map { segment in
            let clampedSpeed = min(segment.speed, cap)
            let weight = configuration.threshold > 0
                ? min(clampedSpeed / configuration.threshold, 1.0)
                : 1.0
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
