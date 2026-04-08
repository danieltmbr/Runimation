import CoreKit
import Foundation
import RunKit
import StravaKit

/// Declares `StravaClient`'s conformance to `ActivityTracker`.
///
/// Kept in the app layer so StravaKit has no dependency on RunKit.
/// Maps between StravaKit-native types (`StravaActivity`) and RunKit
/// protocol types (`Activity`, `ActivitySource`).
///
extension StravaClient: @retroactive ActivityTracker {

    public var id: String { "strava" }

    public var displayName: String { "Strava" }

    public var isConnected: Bool { isAuthenticated }

    // `connect(from:)`, `disconnect()`, and `isLoading` are already
    // defined on StravaClient and satisfy the protocol requirements directly.

    public func activities(before: Date?) async throws -> [Activity] {
        try await stravaActivities(before: before)
            .filter(\.isRun)
            .map { strava in
                Activity(
                    id: String(strava.id),
                    name: strava.name,
                    date: strava.startDate,
                    distance: strava.distance,
                    duration: TimeInterval(strava.movingTime),
                    source: ActivitySource(tracker: id, activityID: String(strava.id))
                )
            }
    }

    public func trackPoints(for source: ActivitySource) async throws -> [GPX.Point] {
        guard let activityID = Int(source.activityID) else {
            throw StravaError.invalidActivityID
        }
        return try await trackPoints(for: activityID)
    }
}
