import CoreKit
import Foundation
import StravaKit

/// A lightweight entry in the Run Library list.
///
/// Carries enough metadata for display (`RunInfoView`) and a `source` that
/// tells `RunLibrary` how to load the full track on demand.
/// Track caching is owned by `RunLibrary`, not by the entry itself.
///
public struct LibraryEntry: Identifiable {

    // MARK: - Source

    public enum Source {
        case strava(activity: StravaActivity)
        case gpx(url: URL)
        case bundled(name: String)
    }

    // MARK: - Properties

    public let id: UUID
    
    public let name: String
    
    public let date: Date
    
    public let distance: Double
    
    public let duration: TimeInterval
    
    public let source: Source

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        name: String,
        date: Date,
        distance: Double,
        duration: TimeInterval,
        source: Source
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
        self.source = source
    }
}

// MARK: - Source: Equatable & Hashable

extension LibraryEntry.Source: Equatable {
    public static func == (lhs: LibraryEntry.Source, rhs: LibraryEntry.Source) -> Bool {
        switch (lhs, rhs) {
        case (.strava(let a), .strava(let b)): return a.id == b.id
        case (.gpx(let a), .gpx(let b)):       return a == b
        case (.bundled(let a), .bundled(let b)): return a == b
        default: return false
        }
    }
}

extension LibraryEntry.Source: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .strava(let activity):
            hasher.combine(0);
            hasher.combine(activity.id)
        case .gpx(let url):
            hasher.combine(1);
            hasher.combine(url)
        case .bundled(let name):
            hasher.combine(2);
            hasher.combine(name)
        }
    }
}

// MARK: - Equatable & Hashable

extension LibraryEntry: Equatable {
    public static func == (lhs: LibraryEntry, rhs: LibraryEntry) -> Bool {
        lhs.id == rhs.id
    }
}

extension LibraryEntry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Convenience Inits

extension LibraryEntry {

    /// Creates an entry from a Strava activity summary.
    ///
    init(activity: StravaActivity) {
        self.init(
            name: activity.name,
            date: activity.startDate,
            distance: activity.distance,
            duration: TimeInterval(activity.movingTime),
            source: .strava(activity: activity)
        )
    }

    /// Creates an entry from a parsed GPX track and the URL it was loaded from.
    ///
    init(track: GPX.Track, url: URL) {
        let duration: TimeInterval
        if let first = track.points.first?.time, let last = track.points.last?.time {
            duration = last.timeIntervalSince(first)
        } else {
            duration = 0
        }
        self.init(
            name: track.name,
            date: track.date ?? Date(),
            distance: 0, // distance derived by RunKit from parsed segments
            duration: duration,
            source: .gpx(url: url)
        )
    }
}
