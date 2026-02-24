import Foundation

struct Run {
    
    /// Segment of a run
    ///
    struct Segment {
        
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
    struct Spectrum {

        let elevation: ClosedRange<Double>

        /// Rate of elevation change in m/s. Negative = descending, positive = ascending.
        ///
        let elevationRate: ClosedRange<Double>

        let heartRate: ClosedRange<Double>

        /// Minimum non zero speed to maximum speed
        ///
        let speed: ClosedRange<Double>

        let time: ClosedRange<TimeInterval>
    }
    
    var duration: TimeInterval {
        spectrum.time.upperBound - spectrum.time.lowerBound
    }
    
    /// Segments of the run
    ///
    let segments: [Segment]
    
    /// Spectrum of the metrics during the run
    ///
    let spectrum: Spectrum
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
        self.init(
            elevation: (elevations.min() ?? 0)...(elevations.max() ?? 0),
            elevationRate: (elevationRates.min() ?? 0)...(elevationRates.max() ?? 0),
            heartRate: (nonZeroHR.min() ?? 0)...(nonZeroHR.max() ?? 0),
            speed: (speeds.min() ?? 0)...(speeds.max() ?? 0),
            time: time
        )
    }
}
