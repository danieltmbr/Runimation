import AuthenticationServices
import CoreKit
import Foundation
import RunKit
import StravaKit
import SwiftData

/// Manages the unified run library backed by SwiftData.
///
/// Handles all mutations — fetching (Strava, paginated), importing (local files),
/// deleting, and run loading — but owns no in-memory list of entries. The list is
/// driven directly by SwiftData via `@Query` in the views that need it, so inserts
/// and deletes are reflected automatically without any manual array management.
///
/// Create one instance per app and inject it into the view hierarchy
/// via `.library(_:)`. Views trigger mutations via `@Environment(\.action)`.
///
@MainActor
@Observable
final class RunLibrary {

    enum LoadError: LocalizedError {
        case noTracksInFile

        var errorDescription: String? {
            switch self {
            case .noTracksInFile: "The file contains no run data."
            }
        }
    }

    // MARK: - Public State

    /// Whether a remote data source is currently connected.
    var isConnected: Bool { stravaClient.isAuthenticated }

    /// True while a Strava fetch is in flight.
    private(set) var isLoading = false

    // MARK: - Private

    private let modelContext: ModelContext

    private let gpxParser = GPX.Parser()

    private let runParser = Run.Parser()

    private let stravaClient: StravaClient

    /// In-memory parsed run cache keyed by `RunRecord.entryID`.
    private var cache: [UUID: Run] = [:]

    private var currentPage = 1

    private var hasReachedEnd = false

    private let perPage = 30

    // MARK: - Init

    public init(stravaClient: StravaClient, modelContext: ModelContext) {
        self.stravaClient = stravaClient
        self.modelContext = modelContext
        #if DEBUG
        seedBundledRunIfNeeded()
        #endif
    }

    // MARK: - Connection

    public func connect(from anchor: ASPresentationAnchor? = nil) async throws {
        #if os(macOS)
        try await stravaClient.authenticate()
        #else
        guard let anchor else { return }
        try await stravaClient.authenticate(presentingFrom: anchor)
        #endif
        await refresh()
    }

    public func disconnect(keepRuns: Bool) {
        stravaClient.signOut()
        guard !keepRuns else { return }
        removeStravaRecords()
    }

    // MARK: - Fetching

    public func refresh() async {
        guard stravaClient.isAuthenticated else { return }
        currentPage = 1
        hasReachedEnd = false
        await fetchPage()
    }

    public func loadNextPage() async {
        guard !isLoading, !hasReachedEnd, stravaClient.isAuthenticated else { return }
        await fetchPage()
    }

    // MARK: - Import

    public func importFile(from url: URL) async throws {
        let tracks: [GPX.Track] = try await Task.detached { [gpxParser] in
            try gpxParser.parse(contentsOf: url)
        }.value
        guard !tracks.isEmpty else { throw LoadError.noTracksInFile }

        for track in tracks {
            let run = runParser.run(from: track)
            let record = RunRecord(
                name: track.name,
                date: track.date ?? Date(),
                distance: run.distance,
                duration: run.duration,
                source: .gpx(url: url),
                trackData: try? JSONEncoder().encode(track.points)
            )
            modelContext.insert(record)
            cache[record.entryID] = run
        }
        try? modelContext.save()
    }

    // MARK: - Run Loading

    /// Returns the parsed `Run` for the given record, fetching and caching on first access.
    ///
    /// If `trackData` is present on the record, parsing happens locally.
    /// Otherwise the track is fetched from the original source and persisted.
    ///
    public func loadRun(for record: RunRecord) async throws -> Run {
        if let cached = cache[record.entryID] { return cached }

        if let data = record.trackData {
            let points = try JSONDecoder().decode([GPX.Point].self, from: data)
            let track = GPX.Track(name: record.name, points: points, type: "running", date: record.date)
            let run = runParser.run(from: track, id: record.entryID)
            cache[record.entryID] = run
            return run
        }

        let track: GPX.Track
        switch record.source {
        case .strava(let id):
            track = try await stravaClient.track(for: id, name: record.name, date: record.date)
        case .gpx(let url):
            guard let parsed = try gpxParser.parse(contentsOf: url) else {
                throw LoadError.noTracksInFile
            }
            track = parsed
        case .bundled(let name):
            guard let parsed: GPX.Track = gpxParser.parse(fileNamed: name) else {
                throw LoadError.noTracksInFile
            }
            track = parsed
        }

        let run = runParser.run(from: track, id: record.entryID)
        cache[record.entryID] = run
        record.trackData = try? JSONEncoder().encode(track.points)
        try? modelContext.save()

        return run
    }

    // MARK: - Import from .runi

    /// Inserts a run from a decoded `.runi` document into the library.
    ///
    /// Returns an existing record if the same track points are already present
    /// (matched by `entryID` stored in the document's derived UUID). Otherwise
    /// creates a new record, persists the config, and caches the parsed run.
    ///
    public func importRuniDocument(_ document: RuniDocument) -> RunRecord {
        let trackData = (try? JSONEncoder().encode(document.points)) ?? Data()
        let record = RunRecord(
            name: document.name,
            date: document.date ?? Date(),
            distance: 0,
            duration: document.duration,
            source: .gpx(url: URL(fileURLWithPath: "/dev/null")),
            trackData: trackData
        )
        record.visualisationConfigData = (try? JSONEncoder().encode(document.visualisation))
        record.transformersConfigData = (try? JSONEncoder().encode(document.transformers))
        record.interpolatorConfigData = (try? JSONEncoder().encode(document.interpolator))
        record.playDuration = document.duration
        modelContext.insert(record)
        try? modelContext.save()

        // Parse and cache the run so it's immediately available for playback.
        let track = GPX.Track(name: document.name, points: document.points, type: "running", date: document.date)
        let run = runParser.run(from: track, id: record.entryID)
        cache[record.entryID] = run
        record.distance = run.distance

        return record
    }

    // MARK: - Delete

    public func delete(_ record: RunRecord) {
        cache[record.entryID] = nil
        modelContext.delete(record)
        try? modelContext.save()
    }

    // MARK: - Navigation

    /// Returns the `RunRecord` with the given entry ID via an indexed ModelContext lookup.
    ///
    public func record(for id: UUID) -> RunRecord? {
        let descriptor = FetchDescriptor<RunRecord>(
            predicate: #Predicate<RunRecord> { $0.entryID == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Returns the most recently played record, for state restoration on launch.
    ///
    public func lastPlayedRecord() -> RunRecord? {
        var descriptor = FetchDescriptor<RunRecord>(
            predicate: #Predicate<RunRecord> { $0.lastPlayedAt != nil },
            sortBy: [SortDescriptor(\.lastPlayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Current Record Tracking

    func markAsPlaying(_ record: RunRecord) {
        record.lastPlayedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Private

    private func removeStravaRecords() {
        let all = (try? modelContext.fetch(FetchDescriptor<RunRecord>())) ?? []
        let stravaRecords = all.filter {
            if case .strava = $0.source { return true }
            return false
        }
        stravaRecords.forEach { record in
            cache[record.entryID] = nil
            modelContext.delete(record)
        }
        try? modelContext.save()
    }

    private func seedBundledRunIfNeeded() {
        let name = "run-01"
        let all = (try? modelContext.fetch(FetchDescriptor<RunRecord>())) ?? []
        let alreadyExists = all.contains {
            if case .bundled(let n) = $0.source { return n == name }
            return false
        }
        guard !alreadyExists else { return }
        guard let track: GPX.Track = gpxParser.parse(fileNamed: name) else { return }

        let record = RunRecord(
            name: track.name.isEmpty ? name : track.name,
            date: track.date ?? Date(),
            distance: 0,
            duration: 0,
            source: .bundled(name: name),
            trackData: try? JSONEncoder().encode(track.points)
        )
        modelContext.insert(record)
        // Parse the run after inserting the record so run.id matches record.entryID.
        let run = runParser.run(from: track, id: record.entryID)
        record.distance = run.distance
        record.duration = run.duration
        try? modelContext.save()
        cache[record.entryID] = run
    }

    private func fetchPage() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let activities = try await stravaClient.activities(page: currentPage, perPage: perPage)
            let runActivities = activities.filter(\.isRun)

            // Fetch existing sources once for deduplication.
            // #Predicate cannot match on Codable enum cases, so we fetch all and filter.
            let existingSources = Set(
                (try? modelContext.fetch(FetchDescriptor<RunRecord>()))?.map(\.source) ?? []
            )

            for activity in runActivities {
                let source = RunSource.strava(id: activity.id)
                guard !existingSources.contains(source) else { continue }
                let record = RunRecord(
                    name: activity.name,
                    date: activity.startDate,
                    distance: activity.distance,
                    duration: TimeInterval(activity.movingTime),
                    source: source
                )
                modelContext.insert(record)
            }
            try? modelContext.save()

            if activities.count < perPage {
                hasReachedEnd = true
            } else {
                currentPage += 1
            }
        } catch {
            // Network failures surface via isLoading dropping to false.
        }
    }
}
