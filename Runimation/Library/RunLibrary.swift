import AuthenticationServices
import CoreKit
import Foundation
import RunKit
import StravaKit
import SwiftData
import Visualiser

/// Manages the unified run library backed by SwiftData.
///
/// Owns the list of `RunRecord` entries, coordinates fetching (Strava, paginated)
/// and importing (local files), and maintains an in-memory `Run` cache keyed by
/// entry UUID. Track data is persisted in `RunRecord.trackData` so subsequent
/// loads are fully offline.
///
/// Create one instance per app and inject it into the view hierarchy
/// via `.library(_:player:visualisation:)`. Views read state via `@LibraryState`
/// and trigger mutations via `@Environment(\.action)`.
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

    /// All entries currently in the library, sorted by date descending.
    private(set) var entries: [RunRecord] = []

    /// Whether a remote data source is currently connected.
    var isConnected: Bool { stravaClient.isAuthenticated }

    /// True while a fetch is in flight.
    private(set) var isLoading = false

    /// The entry ID currently loaded into the player.
    private(set) var currentRecordID: UUID?

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
        loadFromStore()
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

    public func disconnect() {
        stravaClient.signOut()
        entries = entries.filter {
            if case .strava = $0.source { return false }
            return true
        }
    }

    // MARK: - Fetching

    public func refresh() async {
        guard stravaClient.isAuthenticated else { return }
        currentPage = 1
        hasReachedEnd = false
        entries = entries.filter {
            if case .strava = $0.source { return false }
            return true
        }
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
            entries.insert(record, at: 0)
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
            let run = runParser.run(from: track)
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

        let run = runParser.run(from: track)
        cache[record.entryID] = run
        record.trackData = try? JSONEncoder().encode(track.points)
        try? modelContext.save()

        return run
    }

    // MARK: - Delete

    public func delete(_ record: RunRecord) {
        cache[record.entryID] = nil
        entries.removeAll { $0.entryID == record.entryID }
        modelContext.delete(record)
        try? modelContext.save()
    }

    // MARK: - Navigation

    /// Returns the `RunRecord` with the given entry ID.
    ///
    public func record(for id: UUID) -> RunRecord? {
        entries.first { $0.entryID == id }
    }

    // MARK: - Config

    /// Saves the current visualisation and pipeline config to the active run record.
    /// 
    public func saveCurrentConfig(
        visualisation: any Visualisation,
        transformers: [any RunTransformer],
        interpolator: any RunInterpolator,
        duration: RunPlayer.Duration
    ) {
        guard let id = currentRecordID, let record = record(for: id) else { return }
        record.saveConfig(
            visualisation: visualisation,
            transformers: transformers,
            interpolator: interpolator,
            duration: duration
        )
        try? modelContext.save()
    }

    /// Returns the config from the most recently played run that has saved settings.
    ///
    /// Used as the default when playing a run with no previously saved config.
    ///
    public func lastUsedConfig() -> (
        visualisation: any Visualisation,
        transformers: [any RunTransformer],
        interpolator: any RunInterpolator,
        duration: RunPlayer.Duration
    )? {
        let recent = entries
            .filter { $0.hasConfig }
            .max { ($0.lastPlayedAt ?? .distantPast) < ($1.lastPlayedAt ?? .distantPast) }
        guard let record = recent,
              let vis = record.loadVisualisationConfig() else { return nil }
        return (
            visualisation: vis,
            transformers: record.loadTransformersConfig(),
            interpolator: record.loadInterpolatorConfig() ?? LinearRunInterpolator(),
            duration: record.loadDurationConfig() ?? .thirtySeconds
        )
    }

    /// Returns the most recently played record, for state restoration on launch.
    public func lastPlayedRecord() -> RunRecord? {
        entries
            .filter { $0.lastPlayedAt != nil }
            .max { $0.lastPlayedAt! < $1.lastPlayedAt! }
    }

    // MARK: - Current Record Tracking

    func markAsPlaying(_ record: RunRecord) {
        currentRecordID = record.entryID
        record.lastPlayedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Bundled Run

    /// Persists the bundled run as a `RunRecord` on first launch if not already present.
    public func persistBundledRun(track: GPX.Track, name: String) {
        let alreadyExists = entries.contains {
            if case .bundled(let n) = $0.source { return n == name }
            return false
        }
        guard !alreadyExists else { return }

        let run = runParser.run(from: track)
        let record = RunRecord(
            name: track.name.isEmpty ? name : track.name,
            date: track.date ?? Date(),
            distance: run.distance,
            duration: run.duration,
            source: .bundled(name: name),
            trackData: try? JSONEncoder().encode(track.points)
        )
        modelContext.insert(record)
        try? modelContext.save()
        entries.append(record)
        cache[record.entryID] = run
    }

    // MARK: - Private

    private func loadFromStore() {
        let descriptor = FetchDescriptor<RunRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        entries = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchPage() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let activities = try await stravaClient.activities(page: currentPage, perPage: perPage)
            let runActivities = activities.filter(\.isRun)

            for activity in runActivities {
                let source = RunSource.strava(id: activity.id)
                guard !entries.contains(where: { $0.source == source }) else { continue }
                let record = RunRecord(
                    name: activity.name,
                    date: activity.startDate,
                    distance: activity.distance,
                    duration: TimeInterval(activity.movingTime),
                    source: source
                )
                modelContext.insert(record)
                entries.append(record)
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
