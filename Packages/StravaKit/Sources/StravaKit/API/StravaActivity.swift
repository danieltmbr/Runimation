import Foundation

/// Summary of a Strava activity as returned by `GET /api/v3/athlete/activities`.
///
/// Only the fields needed for display and track construction are decoded.
///
public struct StravaActivity: Decodable, Sendable, Identifiable {

    /// Strava activity identifier.
    public let id: Int

    /// User-given name of the activity.
    public let name: String

    /// Activity type string (e.g., `"Run"`, `"TrailRun"`, `"VirtualRun"`).
    public let sportType: String

    /// UTC start time of the activity.
    public let startDate: Date

    /// Total distance in meters.
    public let distance: Double

    /// Moving time in seconds.
    public let movingTime: Int

    /// Total elevation gain in meters.
    public let totalElevationGain: Double

    /// Average heart rate in BPM, if a sensor was present.
    public let averageHeartrate: Double?

    /// Average cadence in steps per minute, if a sensor was present.
    public let averageCadence: Double?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case sportType = "sport_type"
        case startDate = "start_date"
        case distance
        case movingTime = "moving_time"
        case totalElevationGain = "total_elevation_gain"
        case averageHeartrate = "average_heartrate"
        case averageCadence = "average_cadence"
    }
}

// MARK: - Helpers

extension StravaActivity {

    /// True for any run-type sport.
    public var isRun: Bool {
        sportType.lowercased().contains("run")
    }
}
