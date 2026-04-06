import Foundation

/// An opaque reference tying an activity to its source tracker.
///
/// Stored alongside the run record so the library can route
/// track-data requests back to the correct `ActivityTracker`.
///
public struct ActivitySource: Codable, Hashable, Sendable {

    /// The `ActivityTracker.id` of the originating tracker.
    public let tracker: String

    /// The tracker-specific identifier for this activity.
    public let activityID: String

    public init(tracker: String, activityID: String) {
        self.tracker = tracker
        self.activityID = activityID
    }
}

/// A summary of a single activity returned by an `ActivityTracker`.
///
public struct Activity: Sendable, Identifiable, Hashable {
    
    public let id: String
    
    public let name: String
    
    public let date: Date
    
    public let distance: Double
    
    public let duration: TimeInterval
    
    public let source: ActivitySource

    public init(
        id: String,
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: ActivitySource
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
        self.source = source
    }
}
