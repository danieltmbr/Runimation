import Foundation

/// A lightweight value that identifies an activity tracker and carries its
/// display name for use in UI without needing a reference to the tracker itself.
///
/// Mirrors the `RunEntry` pattern — a thin Hashable wrapper that can be
/// stored in views and passed to environment actions without retaining
/// the full `ActivityTracker` object.
///
public struct TrackerID: Hashable, Sendable {

    /// The tracker's stable string identifier (e.g. `"strava"`).
    public let id: String

    /// The human-readable name shown in the UI (e.g. `"Strava"`).
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public extension ActivityTracker {

    /// Creates a `TrackerID` from this tracker's `id` and `displayName`.
    var trackerID: TrackerID {
        TrackerID(id: id, name: displayName)
    }
}
