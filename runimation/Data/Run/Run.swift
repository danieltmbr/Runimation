import Foundation
import CoreGraphics

struct Run: Equatable, Sendable {

    /// Segment of a run
    ///
    struct Segment: Equatable, Sendable {

        /// Direction of the run
        ///
        /// X: east+, west-
        /// Y: north+, south-
        ///
        let direction: CGPoint

        /// Duration of the segment
        ///
        var duration: TimeInterval {
            time.duration
        }

        /// Distance covered in this segment, in meters.
        ///
        var distance: Double { speed * duration }

        /// Elevation in meter
        let elevation: Double

        /// Change in elevation: m/s
        ///
        let elevationRate: Double

        /// BPM
        ///
        let heartRate: Double

        /// Speed in m/s
        ///
        let speed: Double

        /// Time stamps from which the metrics of
        /// the segment were sampled
        ///
        let time: DateInterval
    }

    /// [min, max] ranges of the metrics of the run
    ///
    /// Helps normalising the data and accessing the end of the spectrums quickly.
    ///
    struct Spectrum: Equatable, Sendable {

        let elevation: ClosedRange<Double>

        /// Rate of elevation change in m/s. Negative = descending, positive = ascending.
        ///
        let elevationRate: ClosedRange<Double>

        let heartRate: ClosedRange<Double>

        /// Minimum non zero speed to maximum speed
        ///
        let speed: ClosedRange<Double>

        let time: ClosedRange<TimeInterval>

        /// Total distance of the run: 0...totalMeters
        ///
        let distance: ClosedRange<Double>
    }

    var duration: TimeInterval {
        spectrum.time.upperBound - spectrum.time.lowerBound
    }

    /// Total run distance in meters.
    ///
    var distance: Double { spectrum.distance.upperBound }

    /// Segments of the run
    ///
    let segments: [Segment]

    /// Spectrum of the metrics during the run
    ///
    let spectrum: Spectrum
}

extension Run {

    /// Returns the segment whose metrics correspond to the given time offset
    /// into the run, measured in seconds from the first segment's start.
    ///
    /// Values are linearly interpolated between the two surrounding segments.
    /// Offsets outside the run's range are clamped to the first or last segment.
    ///
    func segment(at timeOffset: TimeInterval) -> Segment {
        guard segments.count > 1 else {
            return segments.first ?? Segment(
                direction: .zero,
                elevation: 0,
                elevationRate: 0,
                heartRate: 0,
                speed: 0,
                time: DateInterval()
            )
        }

        let origin = segments[0].time.start

        if timeOffset <= 0 { return segments[0] }

        let lastOffset = segments.last!.time.start.timeIntervalSince(origin)
        if timeOffset >= lastOffset { return segments.last! }

        // Binary search for the last segment whose start ≤ timeOffset.
        var lo = 0
        var hi = segments.count - 1
        while lo + 1 < hi {
            let mid = (lo + hi) / 2
            if segments[mid].time.start.timeIntervalSince(origin) <= timeOffset {
                lo = mid
            } else {
                hi = mid
            }
        }

        let a = segments[lo]
        let b = segments[hi]
        let dt = b.time.start.timeIntervalSince(a.time.start)
        let t = dt > 0 ? (timeOffset - a.time.start.timeIntervalSince(origin)) / dt : 0

        return Segment(
            direction: CGPoint(
                x: a.direction.x + (b.direction.x - a.direction.x) * t,
                y: a.direction.y + (b.direction.y - a.direction.y) * t
            ),
            elevation: a.elevation + (b.elevation - a.elevation) * t,
            elevationRate: a.elevationRate + (b.elevationRate - a.elevationRate) * t,
            heartRate: a.heartRate + (b.heartRate - a.heartRate) * t,
            speed: a.speed + (b.speed - a.speed) * t,
            time: a.time
        )
    }
}

extension Run.Spectrum {

    /// Builds a spectrum by computing the min/max of each metric across all segments.
    ///
    /// Heart rate zeroes are excluded as they indicate missing sensor data, not an actual reading.
    ///
    init(from segments: [Run.Segment], time: ClosedRange<TimeInterval>) {
        let speeds = segments.map(\.speed)
        let elevations = segments.map(\.elevation)
        let elevationRates = segments.map(\.elevationRate)
        let nonZeroHR = segments.map(\.heartRate).filter { $0 > 0 }
        let totalDistance = segments.reduce(0.0) { $0 + $1.distance }
        self.init(
            elevation: (elevations.min() ?? 0)...(elevations.max() ?? 0),
            elevationRate: (elevationRates.min() ?? 0)...(elevationRates.max() ?? 0),
            heartRate: (nonZeroHR.min() ?? 0)...(nonZeroHR.max() ?? 0),
            speed: (speeds.min() ?? 0)...(speeds.max() ?? 0),
            time: time,
            distance: 0...totalDistance
        )
    }
}
