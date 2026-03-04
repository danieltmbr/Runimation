import Foundation
import RunKit

/// Converts Strava stream data into a `GPX.Track` for processing by `RunPlayer`.
///
/// Uses the streams' `time` offsets as relative timestamps anchored to the Unix
/// epoch — `RunParser` only cares about differences between consecutive points,
/// so absolute dates are not needed.
///
enum StravaTrackMaker {

    /// Creates a `GPX.Track` from Strava stream data.
    ///
    /// - Parameter streams: Raw streams from the Strava API (lat/lng + time required).
    /// - Parameter name: Optional display name; defaults to `"Strava Run"`.
    /// - Returns: A `GPX.Track` ready for `RunPlayer.setRun(_:)`.
    ///
    static func make(from streams: StravaStreams, name: String = "Strava Run") -> GPX.Track {
        let points = makePoints(from: streams)
        return GPX.Track(name: name, points: points, type: "running")
    }

    // MARK: - Private

    private static func makePoints(from streams: StravaStreams) -> [GPX.Point] {
        let coordinates = streams.latlng.data
        let timeOffsets = streams.time.data
        guard !coordinates.isEmpty else { return [] }

        return zip(coordinates, timeOffsets).enumerated().map { index, pair in
            let (coord, offset) = pair
            return GPX.Point(
                cadence: streams.cadence?.data[safe: index] ?? 0,
                elevation: streams.altitude?.data[safe: index] ?? 0,
                heartRate: streams.heartrate?.data[safe: index] ?? 0,
                latitude: coord.first ?? 0,
                longitude: coord.count > 1 ? coord[1] : 0,
                time: Date(timeIntervalSince1970: Double(offset))
            )
        }
    }
}

// MARK: - Collection Extension

private extension Collection {

    /// Returns the element at `index` if it is within bounds, otherwise `nil`.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
