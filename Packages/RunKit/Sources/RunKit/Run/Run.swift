import Foundation
import CoreGraphics

public struct Run: Equatable, Sendable {

    /// Segment of a run
    ///
    public struct Segment: Equatable, Sendable {

        /// Direction of the run
        ///
        /// X: east+, west-
        /// Y: north+, south-
        ///
        public let direction: CGPoint

        /// Duration of the segment
        ///
        public var duration: TimeInterval {
            time.duration
        }

        /// Distance covered in this segment, in meters.
        ///
        public var distance: Double { speed * duration }

        /// Steps per minute. Zero indicates missing sensor data.
        ///
        public let cadence: Double

        /// Elevation in meter
        public let elevation: Double

        /// Change in elevation: m/s
        ///
        public let elevationRate: Double

        /// BPM
        ///
        public let heartRate: Double

        /// Speed in m/s
        ///
        public let speed: Double

        /// Time stamps from which the metrics of
        /// the segment were sampled
        ///
        public let time: DateInterval

        /// An "empty" segment with all zero values.
        ///
        public static let zero = Segment(
            direction: .zero,
            cadence: 0,
            elevation: 0,
            elevationRate: 0,
            heartRate: 0,
            speed: 0,
            time: .init()
        )
    }

    /// [min, max] ranges of the metrics of the run
    ///
    /// Helps normalising the data and accessing the end of the spectrums quickly.
    ///
    public struct Spectrum: Equatable, Sendable {

        /// Minimum to maximum non-zero cadence (spm). Zero values are excluded
        /// as they indicate missing sensor data.
        ///
        public let cadence: ClosedRange<Double>

        public let elevation: ClosedRange<Double>

        /// Rate of elevation change in m/s. Negative = descending, positive = ascending.
        ///
        public let elevationRate: ClosedRange<Double>

        public let heartRate: ClosedRange<Double>

        /// Minimum non zero speed to maximum speed
        ///
        public let speed: ClosedRange<Double>

        public let time: ClosedRange<TimeInterval>

        /// Total distance of the run: 0...totalMeters
        ///
        public let distance: ClosedRange<Double>
    }

    /// Total run distance in meters.
    ///
    public var distance: Double {
        spectrum.distance.upperBound
    }
    
    /// Total run duration in seconds.
    ///
    public var duration: TimeInterval {
        spectrum.time.upperBound - spectrum.time.lowerBound
    }

    /// Segments of the run
    ///
    public let segments: [Segment]

    /// Spectrum of the metrics during the run
    ///
    public let spectrum: Spectrum
}

extension Run.Spectrum {

    /// Builds a spectrum by computing the min/max of each metric across all segments.
    ///
    /// Zero values for heart rate and cadence are excluded as they indicate
    /// missing sensor data, not actual readings.
    ///
    init(from segments: [Run.Segment], time: ClosedRange<TimeInterval>) {
        let speeds = segments.map(\.speed)
        let elevations = segments.map(\.elevation)
        let elevationRates = segments.map(\.elevationRate)
        let nonZeroHR = segments.map(\.heartRate).filter { $0 > 0 }
        let nonZeroCadence = segments.map(\.cadence).filter { $0 > 0 }
        let totalDistance = segments.reduce(0.0) { $0 + $1.distance }
        self.init(
            cadence: (nonZeroCadence.min() ?? 0)...(nonZeroCadence.max() ?? 0),
            elevation: (elevations.min() ?? 0)...(elevations.max() ?? 0),
            elevationRate: (elevationRates.min() ?? 0)...(elevationRates.max() ?? 0),
            heartRate: (nonZeroHR.min() ?? 0)...(nonZeroHR.max() ?? 0),
            speed: (speeds.min() ?? 0)...(speeds.max() ?? 0),
            time: time,
            distance: 0...totalDistance
        )
    }
}
