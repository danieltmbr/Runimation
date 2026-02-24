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
            let points = track.points

            guard points.count >= 2 else {
                return Run(segments: [], spectrum: Spectrum(
                    elevation: 0...0, elevationRate: 0...0,
                    heartRate: 0...0, speed: 0...0, time: 0...0
                ))
            }

            let startTime = points[0].time

            // Filter out consecutive points with no coordinate change.
            // Stops at traffic lights or intentional rest produce a single
            // longer-duration segment rather than many zero-speed duplicates.
            var filtered: [GPX.Point] = [points[0]]
            for i in 1..<points.count {
                let curr = points[i]
                let prev = filtered.last!
                if curr.latitude != prev.latitude || curr.longitude != prev.longitude {
                    filtered.append(curr)
                }
            }

            guard filtered.count >= 2 else {
                return Run(segments: [], spectrum: Spectrum(
                    elevation: 0...0, elevationRate: 0...0,
                    heartRate: 0...0, speed: 0...0, time: 0...0
                ))
            }

            // Build one segment per consecutive filtered-point pair.
            var segments: [Segment] = []
            segments.reserveCapacity(filtered.count - 1)

            for i in 1..<filtered.count {
                let prev = filtered[i - 1]
                let curr = filtered[i]

                let dt = curr.time.timeIntervalSince(prev.time)
                let dist = equirectangularDistance(
                    lat1: prev.latitude, lon1: prev.longitude,
                    lat2: curr.latitude, lon2: curr.longitude
                )

                let speed = dt > 0 ? dist / dt : 0
                let elevationRate = dt > 0 ? (curr.elevation - prev.elevation) / dt : 0

                let dLon = (curr.longitude - prev.longitude) * .pi / 180.0
                let midLat = (prev.latitude + curr.latitude) / 2.0 * .pi / 180.0
                let dx = dLon * cos(midLat)
                let dy = (curr.latitude - prev.latitude) * .pi / 180.0
                let dirLen = sqrt(dx * dx + dy * dy)

                segments.append(Segment(
                    direction: CGPoint(
                        x: dirLen > 1e-12 ? dx / dirLen : 0,
                        y: dirLen > 1e-12 ? dy / dirLen : 0
                    ),
                    elevation: curr.elevation,
                    elevationRate: elevationRate,
                    heartRate: Double(curr.heartRate),
                    speed: speed,
                    time: DateInterval(start: prev.time, end: curr.time)
                ))
            }

            let speeds = segments.map(\.speed)
            let elevations = segments.map(\.elevation)
            let elevationRates = segments.map(\.elevationRate)
            let nonZeroHR = segments.map(\.heartRate).filter { $0 > 0 }
            let totalDuration = filtered.last!.time.timeIntervalSince(startTime)

            let spectrum = Spectrum(
                elevation: (elevations.min() ?? 0)...(elevations.max() ?? 0),
                elevationRate: (elevationRates.min() ?? 0)...(elevationRates.max() ?? 0),
                heartRate: (nonZeroHR.min() ?? 0)...(nonZeroHR.max() ?? 0),
                speed: (speeds.min() ?? 0)...(speeds.max() ?? 0),
                time: 0...totalDuration
            )

            return Run(segments: segments, spectrum: spectrum)
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
