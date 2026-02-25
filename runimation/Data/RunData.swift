import Foundation

struct RunSample {
    let timeOffset: TimeInterval
    let speed: Double          // m/s
    let elevation: Double      // meters
    let elevationRate: Double  // m/s
    let heartRate: Double      // bpm
    let directionX: Double     // east+, west-
    let directionY: Double     // north+, south-
}

struct NormalizedRunSample {
    let timeOffset: TimeInterval
    let speed: Float       // 0...1
    let elevation: Float   // 0...1
    let heartRate: Float   // 0...1
    let dirX: Float        // -1...1
    let dirY: Float        // -1...1
}

struct RunData {
    let samples: [RunSample]
    let normalized: [NormalizedRunSample]
    let totalDuration: TimeInterval

    let maxSpeed: Double
    let minElevation: Double
    let maxElevation: Double
    let minHeartRate: Double
    let maxHeartRate: Double

    init(track: GPX.Track) {
        let points = track.points
        guard points.count >= 2 else {
            self.samples = []
            self.normalized = []
            self.totalDuration = 0
            self.maxSpeed = 0
            self.minElevation = 0
            self.maxElevation = 0
            self.minHeartRate = 0
            self.maxHeartRate = 0
            return
        }

        let startTime = points[0].time
        let duration = points.last!.time.timeIntervalSince(startTime)
        self.totalDuration = duration

        // STEP 1: Extract actual GPS fixes (where coordinates changed)
        // Each fix records the index of the trackpoint where coordinates changed.
        struct GPSFix {
            let index: Int
            let timeOffset: TimeInterval
            let lat: Double
            let lon: Double
            let elevation: Double
        }

        var fixes: [GPSFix] = [
            GPSFix(index: 0, timeOffset: 0,
                   lat: points[0].latitude, lon: points[0].longitude,
                   elevation: points[0].elevation)
        ]

        for i in 1..<points.count {
            let curr = points[i]
            let prev = fixes.last!
            if curr.latitude != prev.lat || curr.longitude != prev.lon {
                fixes.append(GPSFix(
                    index: i,
                    timeOffset: curr.time.timeIntervalSince(startTime),
                    lat: curr.latitude,
                    lon: curr.longitude,
                    elevation: curr.elevation
                ))
            }
        }

        // STEP 2: Compute speed and direction between consecutive GPS fixes
        struct FixSegment {
            let speed: Double       // m/s averaged over the fix interval
            let dirX: Double        // unit direction, east+
            let dirY: Double        // unit direction, north+
            let elevationRate: Double
        }

        var segments: [FixSegment] = []
        for i in 1..<fixes.count {
            let a = fixes[i - 1]
            let b = fixes[i]
            let dt = b.timeOffset - a.timeOffset
            guard dt > 0 else {
                segments.append(FixSegment(speed: 0, dirX: 0, dirY: 0, elevationRate: 0))
                continue
            }

            let dist = Self.equirectangularDistance(
                lat1: a.lat, lon1: a.lon, lat2: b.lat, lon2: b.lon
            )

            // If gap > 10s with no coordinate change, likely paused
            let speed = dist / dt
            let elevationRate = (b.elevation - a.elevation) / dt

            let dLon = (b.lon - a.lon) * .pi / 180.0
            let midLat = (a.lat + b.lat) / 2.0 * .pi / 180.0
            let dx = dLon * cos(midLat)
            let dy = (b.lat - a.lat) * .pi / 180.0
            let dirLen = sqrt(dx * dx + dy * dy)

            let dirX = dirLen > 1e-12 ? dx / dirLen : 0.0
            let dirY = dirLen > 1e-12 ? dy / dirLen : 0.0

            segments.append(FixSegment(speed: speed, dirX: dirX, dirY: dirY, elevationRate: elevationRate))
        }

        // STEP 3: Assign fix-segment values to all original 1-second trackpoints
        // For each trackpoint, find which fix segment it belongs to and use that segment's values.
        var rawSamples: [RunSample] = []
        rawSamples.reserveCapacity(points.count)

        var fixIdx = 0 // index into fixes array
        for i in 0..<points.count {
            let pt = points[i]
            let t = pt.time.timeIntervalSince(startTime)

            // Advance fixIdx to the last fix at or before this trackpoint
            while fixIdx + 1 < fixes.count && fixes[fixIdx + 1].index <= i {
                fixIdx += 1
            }

            // Use the segment from fixIdx to fixIdx+1
            let seg: FixSegment
            if fixIdx < segments.count {
                seg = segments[fixIdx]
            } else {
                // Past the last fix — use last segment or zero
                seg = segments.last ?? FixSegment(speed: 0, dirX: 0, dirY: 0, elevationRate: 0)
            }

            rawSamples.append(RunSample(
                timeOffset: t,
                speed: seg.speed,
                elevation: pt.elevation,
                elevationRate: seg.elevationRate,
                heartRate: Double(pt.heartRate),
                directionX: seg.dirX,
                directionY: seg.dirY
            ))
        }

        // STEP 4: Smooth speed, direction, and elevation with a Gaussian kernel.
        // Gaussian is better than a moving average: it has no sidelobes in the
        // frequency domain, so it cleanly attenuates high-frequency GPS noise
        // without ringing. sigma is in samples (≈seconds at 1 Hz).
        let smoothedSpeed     = Self.gaussianSmooth(rawSamples.map(\.speed),      sigma: 20)
        let smoothedDirX      = Self.gaussianSmooth(rawSamples.map(\.directionX), sigma: 25)
        let smoothedDirY      = Self.gaussianSmooth(rawSamples.map(\.directionY), sigma: 25)
        let smoothedElevation = Self.gaussianSmooth(rawSamples.map(\.elevation),  sigma: 10)

        // Re-normalize smoothed direction to unit vectors, weighted by speed
        var finalDirX = [Double](repeating: 0, count: rawSamples.count)
        var finalDirY = [Double](repeating: 0, count: rawSamples.count)
        for i in 0..<rawSamples.count {
            let dx = smoothedDirX[i]
            let dy = smoothedDirY[i]
            let len = sqrt(dx * dx + dy * dy)
            let speedWeight = min(smoothedSpeed[i] / 1.0, 1.0)
            if len > 1e-12 {
                finalDirX[i] = (dx / len) * speedWeight
                finalDirY[i] = (dy / len) * speedWeight
            }
        }

        // Build final samples
        var finalSamples: [RunSample] = []
        finalSamples.reserveCapacity(rawSamples.count)
        for i in 0..<rawSamples.count {
            let raw = rawSamples[i]
            finalSamples.append(RunSample(
                timeOffset: raw.timeOffset,
                speed: smoothedSpeed[i],
                elevation: smoothedElevation[i],
                elevationRate: raw.elevationRate,
                heartRate: raw.heartRate,
                directionX: finalDirX[i],
                directionY: finalDirY[i]
            ))
        }

        // Metrics view gets raw (unsmoothed) data so charts reflect actual recorded values.
        // The shader and diagnostics overlay use `normalized` which is derived from
        // finalSamples (smoothed) below.
        self.samples = rawSamples

        // STEP 5: Compute stats and normalize
        let speeds = finalSamples.map(\.speed)
        let elevations = finalSamples.map(\.elevation)
        let heartRates = finalSamples.map(\.heartRate)

        let sortedSpeeds = speeds.sorted()
        let p98Index = Int(Double(sortedSpeeds.count) * 0.98)
        self.maxSpeed = sortedSpeeds[min(p98Index, sortedSpeeds.count - 1)]

        self.minElevation = elevations.min() ?? 0
        self.maxElevation = elevations.max() ?? 1

        let nonZeroHR = heartRates.filter { $0 > 0 }
        self.minHeartRate = nonZeroHR.min() ?? 0
        self.maxHeartRate = nonZeroHR.max() ?? 1

        let normMaxSpeed = self.maxSpeed
        let normMinEle = self.minElevation
        let normEleRange = self.maxElevation - self.minElevation
        let normMinHR = self.minHeartRate
        let normHRRange = self.maxHeartRate - self.minHeartRate

        self.normalized = finalSamples.map { s in
            NormalizedRunSample(
                timeOffset: s.timeOffset,
                speed: Float(normMaxSpeed > 0 ? min(s.speed / normMaxSpeed, 1.0) : 0),
                elevation: Float(normEleRange > 0 ? (s.elevation - normMinEle) / normEleRange : 0.5),
                heartRate: Float(normHRRange > 0 ? (s.heartRate - normMinHR) / normHRRange : 0.5),
                dirX: Float(s.directionX),
                dirY: Float(s.directionY)
            )
        }
    }

    // MARK: - Interpolation

    /// Interpolates normalized values at a given time offset using binary search + lerp.
    func interpolated(at timeOffset: TimeInterval) -> NormalizedRunSample {
        guard normalized.count >= 2 else {
            return normalized.first ?? NormalizedRunSample(
                timeOffset: 0, speed: 0, elevation: 0.5, heartRate: 0.5, dirX: 0, dirY: 0
            )
        }

        // Clamp to valid range
        let t = max(0, min(timeOffset, totalDuration))

        // Binary search for bracket
        var lo = 0
        var hi = normalized.count - 1
        while lo < hi - 1 {
            let mid = (lo + hi) / 2
            if normalized[mid].timeOffset <= t {
                lo = mid
            } else {
                hi = mid
            }
        }

        let a = normalized[lo]
        let b = normalized[hi]

        let segmentDuration = b.timeOffset - a.timeOffset
        guard segmentDuration > 0 else { return a }

        let frac = Float((t - a.timeOffset) / segmentDuration)

        return NormalizedRunSample(
            timeOffset: t,
            speed: a.speed + (b.speed - a.speed) * frac,
            elevation: a.elevation + (b.elevation - a.elevation) * frac,
            heartRate: a.heartRate + (b.heartRate - a.heartRate) * frac,
            dirX: a.dirX + (b.dirX - a.dirX) * frac,
            dirY: a.dirY + (b.dirY - a.dirY) * frac
        )
    }

    // MARK: - Private Helpers

    private static func equirectangularDistance(
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

    /// Gaussian kernel smoother. sigma is the standard deviation in samples.
    /// Uses a ±3σ truncated kernel, normalised so edge samples aren't darkened.
    private static func gaussianSmooth(_ values: [Double], sigma: Double) -> [Double] {
        guard values.count > 1, sigma > 0 else { return values }
        let halfWidth = Int(ceil(sigma * 3))
        let n = values.count
        var result = [Double](repeating: 0, count: n)
        let twoSigmaSq = 2.0 * sigma * sigma
        for i in 0..<n {
            var weightSum = 0.0
            var valueSum  = 0.0
            let lo = max(0, i - halfWidth)
            let hi = min(n - 1, i + halfWidth)
            for j in lo...hi {
                let d = Double(j - i)
                let w = exp(-(d * d) / twoSigmaSq)
                weightSum += w
                valueSum  += values[j] * w
            }
            result[i] = weightSum > 0 ? valueSum / weightSum : values[i]
        }
        return result
    }
}
