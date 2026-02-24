import Foundation

extension Run {
    
    /// Run Parser maps a GPX Track into a Run.
    ///
    /// The parser turns a track into a run by filtering out
    /// sample points with no coordinate changes, pairs them
    /// sequentally and make segments of them by calculating
    /// the direction, duration, speed, elevation, elevation change
    /// and heart rate.
    ///
    /// While creating the segments the processor also collects
    /// the spectrum of these metrics, which is basically their
    /// minimum and maximum values.
    ///
    struct Parser {
        
        func run(from track: GPX.Track) -> Run {
            
        }
        
        private func equirectangularDistance(
            lat1: Double, lon1: Double,
            lat2: Double, lon2: Double
        ) -> Double {
            let R = 6_371_000.0
            let dLat = (lat2 - lat1) * .pi / 180.0
            let dLon = (lon2 - lon1) * .pi / 180.0
            let midLat = (lat1 + lat2) / 2.0 * .pi / 180.0
            let x = dLon * cos(midLat)
            let y = dLat
            return R * sqrt(x * x + y * y)
        }
    }
}
