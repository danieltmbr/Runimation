import Foundation

// MARK: - Protocol

/// Transforms a `Run` into chart-ready `RunChart.Data` for a specific metric.
///
/// Adopt this protocol to define new metric mappings. The default extension
/// provides downsampling and time-conversion helpers that implementations can reuse.
///
protocol RunChartMapper {
    func map(run: Run, progress: Double) -> RunChart.Data
}

// MARK: - Convenience

extension Run {
    /// Maps the run's data for a given metric into chart-ready form.
    ///
    func mapped(by mapper: some RunChartMapper, progress: Double) -> RunChart.Data {
        mapper.map(run: self, progress: progress)
    }
}

// MARK: - Shared helpers

extension RunChartMapper {

    /// Reduces `segments` to at most `maxPoints` evenly spaced samples.
    ///
    func downsample(_ segments: [Run.Segment], maxPoints: Int = 500) -> [Run.Segment] {
        let step = max(1, segments.count / maxPoints)
        return stride(from: 0, to: segments.count, by: step).map { segments[$0] }
    }

    /// Returns the elapsed time in minutes from `origin` to the start of `segment`.
    ///
    func minutes(of segment: Run.Segment, origin: Date) -> Double {
        segment.time.start.timeIntervalSince(origin) / 60.0
    }

    /// Returns the current playhead position in minutes (the unit used for X axes).
    ///
    func playheadMinutes(progress: Double, run: Run) -> Double {
        progress * run.duration / 60.0
    }

    /// Returns the total run duration in minutes, with a minimum of 1.
    ///
    func totalDurationMinutes(_ run: Run) -> Double {
        max(run.duration / 60.0, 1)
    }
}
