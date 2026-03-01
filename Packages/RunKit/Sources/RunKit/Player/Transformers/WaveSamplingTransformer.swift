import Foundation
import CoreGraphics

/// WaveSamplingTransformer reduces a run to a fixed number of synthetic segments,
/// each assembled from the most extreme values across a window of original data.
///
/// The output count is controlled by `targetCount`; the window size is derived
/// automatically as `segments.count / targetCount`. Odd-indexed windows draw
/// the `rank`-th highest value from each metric; even-indexed windows draw the
/// `rank`-th lowest. This alternation introduces a wave-like oscillation into
/// the sparse dataset, making interpolation strategy differences clearly visible.
///
/// Each output segment is **synthetic**: its metric values may come from different
/// original segments within the window, so the resulting combination may never
/// have existed at any real moment during the run. The direction field uses the
/// normalised mean of the window's direction vectors.
///
/// The segment timestamp is the mean start time of the window, so output points
/// are not perfectly uniform — they reflect the actual density of the GPS data.
///
public struct WaveSamplingTransformer: RunTransformer {

    /// Number of segments in the output run.
    ///
    public let targetCount: Int

    /// Rank offset for value selection (1 = absolute max/min).
    ///
    /// A value of 3 picks the 3rd-highest or 3rd-lowest within the window,
    /// providing light outlier protection against GPS anomalies.
    ///
    public let rank: Int

    public init(targetCount: Int, rank: Int) {
        self.targetCount = targetCount
        self.rank = rank
    }

    public func transform(_ run: Run) -> Run {
        let segments = run.segments
        guard segments.count > targetCount, targetCount > 0 else { return run }

        let windowSize = segments.count / targetCount

        let synthetic: [Run.Segment] = (0..<targetCount).map { i in
            let start = i * windowSize
            let end = (i == targetCount - 1) ? segments.count : start + windowSize
            let window = Array(segments[start..<end])
            return syntheticSegment(from: window, pickHighest: i.isMultiple(of: 2))
        }

        return Run(segments: synthetic, spectrum: .init(from: synthetic, time: run.spectrum.time))
    }

    // MARK: - Private

    private func syntheticSegment(from window: [Run.Segment], pickHighest: Bool) -> Run.Segment {
        let meanStart = window.map { $0.time.start.timeIntervalSinceReferenceDate }.reduce(0.0, +) / Double(window.count)
        let meanDuration = window.map(\.time.duration).reduce(0.0, +) / Double(window.count)

        return Run.Segment(
            direction: meanDirection(from: window),
            elevation:     nth(window.map(\.elevation),     highest: pickHighest),
            elevationRate: nth(window.map(\.elevationRate), highest: pickHighest),
            heartRate:     nth(window.map(\.heartRate),     highest: pickHighest),
            speed:         nth(window.map(\.speed),         highest: pickHighest),
            time: DateInterval(
                start: Date(timeIntervalSinceReferenceDate: meanStart),
                duration: meanDuration
            )
        )
    }

    /// Returns the `rank`-th highest or lowest value from `values`.
    ///
    private func nth(_ values: [Double], highest: Bool) -> Double {
        let sorted = highest ? values.sorted(by: >) : values.sorted(by: <)
        return sorted[min(rank - 1, sorted.count - 1)]
    }

    /// Returns the normalised vector mean of the window's direction fields.
    ///
    private func meanDirection(from window: [Run.Segment]) -> CGPoint {
        let count = Double(window.count)
        let meanX = window.reduce(0.0) { $0 + $1.direction.x } / count
        let meanY = window.reduce(0.0) { $0 + $1.direction.y } / count
        let magnitude = sqrt(meanX * meanX + meanY * meanY)
        guard magnitude > 0 else { return .zero }
        return CGPoint(x: meanX / magnitude, y: meanY / magnitude)
    }
}

extension RunTransformer where Self == TransformerChain {
    
    static var sparsed: Self {
        self.sparsed()
    }
    
    static func sparsed(targetCount: Int = 15, rank: Int = 5) -> Self {
        TransformerChain(
            transformers: [WaveSamplingTransformer(targetCount: targetCount, rank: rank)]
        )
    }
    
    var sparsed: Self {
        self.sparsed()
    }
    
    func sparsed(targetCount: Int = 15, rank: Int = 5) -> Self {
        self.append(transformer: .sparsed(targetCount: targetCount, rank: rank))
    }
}
