import Foundation
import RunKit

/// Transforms a `Run` into chart-ready `RunChart.Data` for a specific metric,
/// and formats a single `Run.Segment` value for display as a label.
///
/// Adopt this protocol to define new metric mappings. The default extension
/// provides downsampling and time-conversion helpers that implementations can reuse.
///
public protocol RunChartMapper: RunChartDataMapper, RunChartValueMapper {}

// MARK: - Value Mapper

/// Transforms a `Run.Segment` for specific metric to a value for display as a label.
///
/// Adopt this protocol to define new metric mappings. The default extension
/// provides downsampling and time-conversion helpers that implementations can reuse.
///
public protocol RunChartValueMapper: Sendable {
    
    /// Formats the relevant metric value from a single segment into a display string.
    ///
    func value(from segment: Run.Segment) -> String
}

// MARK: - Data Mapper

/// Transforms a `Run` into chart-ready `RunChart.Data` for a specific metric
///
/// Adopt this protocol to define new metric mappings. The default extension
/// provides downsampling and time-conversion helpers that implementations can reuse.
///
public protocol RunChartDataMapper: Sendable {
    
    /// Maps the full run into chart-ready data for this metric.
    ///
    func map(run: Run) -> RunChart.Data
}

extension RunChartDataMapper {
    
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
    
    /// Returns the total run duration in minutes, with a minimum of 1.
    ///
    func totalDurationMinutes(_ run: Run) -> Double {
        max(run.duration / 60.0, 1)
    }
}

// MARK: - Convenience

extension Run {
    /// Maps the run's data for a given metric into chart-ready form.
    ///
    public func mapped(by mapper: some RunChartDataMapper) -> RunChart.Data {
        mapper.map(run: self)
    }
}
