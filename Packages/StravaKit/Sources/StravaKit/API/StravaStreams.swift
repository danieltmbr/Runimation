import Foundation

/// Raw stream data returned by `GET /api/v3/activities/{id}/streams?key_by_type=true`.
///
/// Each field wraps a `StreamData` envelope containing the `data` array.
/// Optional streams are absent when the activity has no sensor data for them.
///
struct StravaStreams: Decodable, Sendable {

    /// Coordinate pairs `[latitude, longitude]` for each sample.
    let latlng: StreamData<[Double]>

    /// Altitude in meters for each sample. Absent if no elevation data.
    let altitude: StreamData<Double>?

    /// Elapsed seconds from the activity start for each sample.
    let time: StreamData<Int>

    /// Heart rate in BPM for each sample. Absent if no HR monitor was used.
    let heartrate: StreamData<Int>?

    /// Cadence in steps per minute for each sample. Absent if no foot pod was used.
    let cadence: StreamData<Int>?

    // MARK: - Inner Types

    /// A single typed stream from the Strava API.
    struct StreamData<T: Decodable & Sendable>: Decodable, Sendable {
        let data: [T]
    }
}
