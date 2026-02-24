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
                return Run(segments: [], spectrum: Spectrum(from: [], time: 0...0))
            }

            let unique = filterDuplicates(points)
            guard unique.count >= 2 else {
                return Run(segments: [], spectrum: Spectrum(from: [], time: 0...0))
            }

            let segments = makeSegments(from: unique)
            let duration = unique.last!.time.timeIntervalSince(unique.first!.time)
            return Run(
                segments: segments,
                spectrum: Spectrum(from: segments, time: 0...duration)
            )
        }

        // MARK: - Private

        /// Removes consecutive points with identical coordinates.
        /// Stops at traffic lights or intentional rests produce a single
        /// longer-duration segment rather than many zero-speed duplicates.
        ///
        private func filterDuplicates(_ points: [GPX.Point]) -> [GPX.Point] {
            var unique: [GPX.Point] = [points[0]]
            for i in 1..<points.count {
                let curr = points[i]
                let prev = unique.last!
                if curr.latitude != prev.latitude || curr.longitude != prev.longitude {
                    unique.append(curr)
                }
            }
            return unique
        }

        private func makeSegments(from points: [GPX.Point]) -> [Segment] {
            var segments: [Segment] = []
            segments.reserveCapacity(points.count - 1)
            for i in 1..<points.count {
                segments.append(makeSegment(from: points[i - 1], to: points[i]))
            }
            return segments
        }

        private func makeSegment(from prev: GPX.Point, to curr: GPX.Point) -> Segment {
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

            return Segment(
                direction: CGPoint(
                    x: dirLen > 1e-12 ? dx / dirLen : 0,
                    y: dirLen > 1e-12 ? dy / dirLen : 0
                ),
                elevation: curr.elevation,
                elevationRate: elevationRate,
                heartRate: Double(curr.heartRate),
                speed: speed,
                time: DateInterval(start: prev.time, end: curr.time)
            )
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
