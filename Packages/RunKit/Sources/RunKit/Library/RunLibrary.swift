import AuthenticationServices
import CoreKit
import Foundation

/// Manages the unified run library backed by a `RunStorage`.
///
/// Handles all mutations — syncing from activity trackers, importing
/// local track data, deleting, and run loading — but owns no in-memory
/// list of entries. The list is driven directly by the persistence layer
/// via `@Query` in the views that need it, so inserts and deletes are
/// reflected automatically without any manual array management.
///
/// Create one instance per app and inject it into the view hierarchy
/// via `.library(_:)`. Views trigger mutations via `@Environment(\.action)`.
///
@MainActor
@Observable
public final class RunLibrary {

    // MARK: - Public State

    /// Whether any tracker is currently connected.
    ///
    public var isConnected: Bool {
        trackers.contains { $0.isConnected }
    }

    /// Whether any tracker is currently fetching activities.
    ///
    public var isLoading: Bool {
        trackers.contains { $0.isLoading }
    }

    // MARK: - Dependencies

    public let trackers: [any ActivityTracker]

    private let storage: any RunStorage

    private let gpxParser: GPX.Parser

    private let runParser: Run.Parser

    /// In-memory parsed run cache keyed by run UUID.
    ///
    private var cache: [UUID: Run] = [:]

    /// Oldest activity date fetched per tracker, used as the `before` cursor.
    ///
    private var cursors: [String: Date] = [:]

    /// Tracker IDs for which all pages have been fetched.
    ///
    private var endReached: Set<String> = []

    // MARK: - Init

    public init(
        trackers: [any ActivityTracker],
        storage: any RunStorage,
        gpxParser: GPX.Parser = GPX.Parser(),
        runParser: Run.Parser = Run.Parser()
    ) {
        self.trackers = trackers
        self.storage = storage
        self.gpxParser = gpxParser
        self.runParser = runParser
    }

    // MARK: - Connection

    /// Connects a tracker and immediately refreshes its activities.
    public func connect(_ tracker: any ActivityTracker, from anchor: ASPresentationAnchor?) async throws {
        try await tracker.connect(from: anchor)
        await refresh()
    }

    /// Disconnects a tracker, optionally removing its stored runs.
    public func disconnect(_ tracker: any ActivityTracker, keepRuns: Bool) {
        tracker.disconnect()
        guard !keepRuns else { return }
        removeRuns(from: tracker)
    }

    // MARK: - Fetching

    /// Resets pagination cursors and fetches fresh data from all connected trackers.
    public func refresh() async {
        cursors.removeAll()
        endReached.removeAll()
        await fetchNextPage()
    }

    /// Fetches the next page of activities from all connected trackers.
    ///
    /// Uses timestamp-based cursors: each tracker receives the oldest date
    /// seen so far as `before`, so pages are stable even when new activities
    /// are added between fetches.
    ///
    public func fetchNextPage() async {
        for tracker in trackers where tracker.isConnected && !endReached.contains(tracker.id) {
            let before = cursors[tracker.id]
            let activities = (try? await tracker.activities(before: before)) ?? []

            if activities.isEmpty {
                endReached.insert(tracker.id)
            } else if let oldest = activities.map(\.date).min() {
                cursors[tracker.id] = oldest
            }

            for activity in activities {
                guard !storage.exists(source: activity.source) else { continue }
                storage.insert(
                    name: activity.name,
                    date: activity.date,
                    distance: activity.distance,
                    duration: activity.duration,
                    source: .tracker(activity.source),
                    trackData: nil
                )
            }
        }
    }

    // MARK: - Run Loading

    /// Returns the parsed `Run` for the given entry, fetching and caching on first access.
    ///
    /// If `trackData` is stored for the entry, parsing happens locally.
    /// Otherwise the origin is resolved — tracker activities are fetched
    /// remotely, bundled and file runs are re-parsed locally.
    ///
    public func loadRun(for entry: RunEntry) async throws -> Run {
        if let cached = cache[entry.id] { return cached }

        if let data = storage.trackData(for: entry.id) {
            let name = storage.name(for: entry.id) ?? ""
            return try parseAndCache(data: data, name: name, id: entry.id)
        }

        guard let origin = storage.origin(for: entry.id) else {
            throw LoadError.notFound
        }

        let track = try await fetchTrack(for: origin)
        let data = try JSONEncoder().encode(track.points)
        storage.storeTrackData(data, for: entry.id)

        let run = runParser.run(from: track, id: entry.id)
        cache[entry.id] = run
        storage.updateDistance(run.distance, for: entry.id)
        return run
    }

    // MARK: - Import

    /// Imports a parsed run from raw track points into the library.
    ///
    /// Returns the `RunEntry` for the newly created record.
    ///
    @discardableResult
    public func importTrack(
        name: String,
        date: Date,
        points: [GPX.Point],
        source: RunOrigin
    ) -> RunEntry {
        let trackData = try? JSONEncoder().encode(points)
        let track = GPX.Track(name: name, points: points, type: "running", date: date)
        let run = runParser.run(from: track)
        let id = storage.insert(
            name: name,
            date: date,
            distance: run.distance,
            duration: run.duration,
            source: source,
            trackData: trackData
        )
        cache[id] = run
        return RunEntry(id: id)
    }

    // MARK: - Delete

    public func delete(_ entry: RunEntry) {
        cache[entry.id] = nil
        storage.delete(id: entry.id)
    }

    // MARK: - NowPlaying

    /// Records that a run has just been loaded for playback.
    public func markAsPlaying(_ entry: RunEntry) {
        storage.markAsPlayed(id: entry.id)
    }

    /// The most recently played run entry, for state restoration on launch.
    public var lastPlayedEntry: RunEntry? {
        storage.lastPlayedID().map { RunEntry(id: $0) }
    }

    // MARK: - Private

    private func parseAndCache(data: Data, name: String, id: UUID) throws -> Run {
        let points = try JSONDecoder().decode([GPX.Point].self, from: data)
        let track = GPX.Track(name: name, points: points, type: "running", date: nil)
        let run = runParser.run(from: track, id: id)
        cache[id] = run
        return run
    }

    private func fetchTrack(for origin: RunOrigin) async throws -> GPX.Track {
        switch origin {
        case .tracker(let source):
            guard let tracker = trackers.first(where: { $0.id == source.tracker })
            else { throw LoadError.trackerNotFound }
            let points = try await tracker.trackPoints(for: source)
            return GPX.Track(name: "", points: points, type: "running", date: nil)
        case .file(let url):
            let tracks: [GPX.Track] = (try? gpxParser.parse(contentsOf: url)) ?? []
            guard let track = tracks.first else { throw LoadError.noTracksInFile }
            return track
        case .bundled(let name):
            let bundled: [GPX.Track] = gpxParser.parse(fileNamed: name)
            guard let track = bundled.first else { throw LoadError.noTracksInFile }
            return track
        case .document:
            throw LoadError.noTracksInFile
        }
    }

    private func removeRuns(from tracker: any ActivityTracker) {
        let ids = storage.ids(fromTracker: tracker.id)
        for id in ids {
            cache[id] = nil
            storage.delete(id: id)
        }
    }

    // MARK: - Errors

    public enum LoadError: LocalizedError {
        case notFound
        case noTracksInFile
        case trackerNotFound

        public var errorDescription: String? {
            switch self {
            case .notFound: "The run could not be found in the library."
            case .noTracksInFile: "The file contains no run data."
            case .trackerNotFound: "The source tracker is no longer connected."
            }
        }
    }
}
