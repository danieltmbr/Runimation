import AuthenticationServices
import CoreKit
import Foundation

/// Manages the unified run library backed by a `RunStorage`.
///
/// Handles all mutations — syncing from activity trackers, importing
/// local track data, deleting, and run loading — but owns no in-memory
/// list of entries. The list is driven directly by the persistence layer
/// via `@RunLibraryQuery` in the views that need it, so inserts and
/// deletes are reflected automatically without any manual array management.
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

    /// In-memory parsed run cache keyed by `RunID`.
    ///
    private var cache: [RunID: Run] = [:]

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

    /// Returns `true` if the run's track data is already stored locally,
    /// meaning playback will not require a network call.
    ///
    public func hasPersistedTrack(for id: RunID) -> Bool {
        storage.trackData(for: id) != nil
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

    /// Loads the requested detail properties for an item and returns an updated copy.
    ///
    /// `.run` — resolves track data from cache, local storage, or the original
    /// source (tracker, bundled file, or local file). Safe to call repeatedly;
    /// already-loaded properties are preserved.
    ///
    /// `.config` — reads the persisted config blobs from storage.
    /// Returns `nil` config if the record has no saved config yet.
    ///
    /// Convenience overload — resolves the `RunItem` by ID then delegates to the canonical form.
    public func load(_ id: RunID, with properties: Set<RunItem.Property>) async throws -> RunItem {
        guard let item = item(for: id) else { throw LoadError.notFound }
        return try await load(item, with: properties)
    }

    public func load(_ item: RunItem, with properties: Set<RunItem.Property>) async throws -> RunItem {
        var result = item
        if properties.contains(.run) {
            result = result.adding(run: try await loadRun(for: item))
        }
        if properties.contains(.config) {
            let config = storage.config(for: item.id) ?? RunConfig(
                visualisationConfigData: nil,
                transformersConfigData: nil,
                interpolatorConfigData: nil,
                playDuration: nil
            )
            result = result.adding(config: config)
        }
        return result
    }

    // MARK: - Import

    /// Imports a parsed run from raw track points into the library.
    ///
    /// Returns the `RunItem` for the newly created record, with no detail
    /// properties populated. Call `load(_:with:)` afterwards if you need
    /// the run data or config immediately.
    ///
    @discardableResult
    public func importTrack(
        name: String,
        date: Date,
        points: [GPX.Point],
        source: RunOrigin
    ) -> RunItem {
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
        return RunItem(
            id: id,
            name: name,
            date: date,
            distance: run.distance,
            duration: run.duration,
            source: source
        )
    }

    // MARK: - Config

    /// Persists config blobs for the given run (e.g. after importing a `.runi` document).
    public func storeConfig(_ config: RunConfig, for id: RunID) {
        storage.storeConfig(config, for: id)
    }

    /// Convenience overload — extracts `id` and delegates to the canonical form.
    public func storeConfig(_ config: RunConfig, for item: RunItem) {
        storeConfig(config, for: item.id)
    }

    // MARK: - Raw Track Data

    // TODO: [GPX.Point] should not be a fundamental data type of the Library anymore
    // It's an implementation detail we used for importing GPX files
    // We need to have our own dedicated type.
    //
    /// Returns the raw GPS track points for the given run.
    ///
    /// Only valid after calling `load(_:with: [.run])`, which guarantees
    /// track data has been written to storage.
    ///
    public func rawPoints(for id: RunID) throws -> [GPX.Point] {
        guard let data = storage.trackData(for: id) else { throw LoadError.notFound }
        return try JSONDecoder().decode([GPX.Point].self, from: data)
    }

    /// Convenience overload — extracts `id` and delegates to the canonical form.
    public func rawPoints(for item: RunItem) throws -> [GPX.Point] {
        try rawPoints(for: item.id)
    }

    // MARK: - Delete

    /// Removes the run with the given ID from the library and cache.
    public func delete(_ id: RunID) {
        cache[id] = nil
        storage.delete(id: id)
    }

    /// Convenience overload — extracts `id` and delegates to the canonical form.
    public func delete(_ item: RunItem) {
        delete(item.id)
    }

    // MARK: - NowPlaying

    /// Records that a run has just been loaded for playback.
    public func markAsPlaying(_ id: RunID) {
        storage.markAsPlayed(id: id)
    }

    /// Convenience overload — extracts `id` and delegates to the canonical form.
    public func markAsPlaying(_ item: RunItem) {
        markAsPlaying(item.id)
    }

    /// The most recently played run, for state restoration on launch.
    /// Returns `nil` if no run has been played or storage has no record.
    public var lastPlayedItem: RunItem? {
        guard let id = storage.lastPlayedID() else { return nil }
        return item(for: id)
    }

    // MARK: - Private

    /// Builds a minimal `RunItem` from storage metadata for the given ID.
    private func item(for id: RunID) -> RunItem? {
        guard let name = storage.name(for: id),
              let origin = storage.origin(for: id)
        else { return nil }
        return RunItem(id: id, name: name, date: Date(), distance: 0, duration: 0, source: origin)
    }

    /// Returns the parsed `Run` for the given item, fetching and caching on first access.
    private func loadRun(for item: RunItem) async throws -> Run {
        if let cached = cache[item.id] { return cached }

        if let data = storage.trackData(for: item.id) {
            let name = storage.name(for: item.id) ?? ""
            return try parseAndCache(data: data, name: name, id: item.id)
        }

        guard let origin = storage.origin(for: item.id) else {
            throw LoadError.notFound
        }

        let track = try await fetchTrack(for: origin)
        let data = try JSONEncoder().encode(track.points)
        storage.storeTrackData(data, for: item.id)

        let run = runParser.run(from: track, id: item.id)
        cache[item.id] = run
        storage.updateDistance(run.distance, for: item.id)
        return run
    }

    private func parseAndCache(data: Data, name: String, id: RunID) throws -> Run {
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
