import AuthenticationServices
import CoreKit
import Foundation
import RunKit
import StravaKit

/// Manages the unified run library for the session.
///
/// Owns the in-memory list of `LibraryEntry` items, coordinates
/// fetching (Strava, paginated) and importing (local files), and
/// maintains an internal `Run` cache keyed by source.
/// Session-only — contents are not persisted across launches (deferred to Phase 5).
///
/// Create one instance per app and inject it into the view hierarchy
/// via `.library(_:player:)`. Views read state via `@LibraryState` and
/// trigger mutations via `@Environment(\.action)`.
///
@MainActor
@Observable
public final class RunLibrary {
    
    public enum LoadError: LocalizedError {
        case noTracksInFile
        
        public var errorDescription: String? {
            switch self {
            case .noTracksInFile: "The file contains no run data."
            }
        }
    }

    // MARK: - Public State

    /// All entries currently in the library.
    /// Remote entries are appended as pages are fetched; imported entries are prepended.
    ///
    public private(set) var entries: [LibraryEntry] = []

    /// Whether a data source is currently connected.
    ///
    /// Named "connected" rather than "authenticated" to remain source-agnostic
    /// (Strava today, Apple Health or others in the future).
    ///
    public var isConnected: Bool { stravaClient.isAuthenticated }

    /// True while a fetch is in flight.
    ///
    public private(set) var isLoading = false

    // MARK: - Private

    private let gpxParser = GPX.Parser()
    
    private let runParser = Run.Parser()
    
    private let stravaClient: StravaClient
    
    /// In-memory run cache. Keyed by `LibraryEntry.Source` so runs are shared across
    /// any number of entries pointing to the same source.
    private var cache: [LibraryEntry.Source: Run] = [:]
    
    private var currentPage = 1
    
    private var hasReachedEnd = false
    
    private let perPage = 30

    // MARK: - Init

    public init(stravaClient: StravaClient) {
        self.stravaClient = stravaClient
    }

    // MARK: - Connection

    /// Connects to the data source and populates the library.
    ///
    /// On iOS, pass a presentation anchor for the authentication session.
    /// On macOS, the anchor parameter is ignored.
    /// On success, triggers a `refresh()` to load the first page.
    ///
    public func connect(from anchor: ASPresentationAnchor? = nil) async throws {
        #if os(macOS)
        try await stravaClient.authenticate()
        #else
        guard let anchor else { return }
        try await stravaClient.authenticate(presentingFrom: anchor)
        #endif
        await refresh()
    }

    /// Disconnects from the data source and removes remote entries.
    ///
    public func disconnect() {
        stravaClient.signOut()
        entries = entries.filter { entry in
            switch entry.source {
            case .gpx, .bundled: return true
            case .strava: return false
            }
        }
    }

    // MARK: - Fetching

    /// Clears remote entries and re-fetches from the first page.
    ///
    /// Locally imported entries and the run cache are preserved.
    ///
    public func refresh() async {
        guard stravaClient.isAuthenticated else { return }
        currentPage = 1
        hasReachedEnd = false
        entries = entries.filter { entry in
            switch entry.source {
            case .gpx, .bundled: return true
            case .strava: return false
            }
        }
        await fetchPage()
    }

    /// Fetches the next page of remote entries and appends them.
    ///
    /// No-op if already loading, at the end of the list, or not authenticated.
    ///
    public func loadNextPage() async {
        guard !isLoading, !hasReachedEnd, stravaClient.isAuthenticated else { return }
        await fetchPage()
    }

    // MARK: - Import

    /// Parses a file at the given URL and prepends the resulting entries.
    ///
    /// The file is read and parsed on a background thread. Throws if the
    /// URL is unreadable or the file contains no valid run data.
    /// Parsed runs are immediately cached.
    ///
    public func importFile(from url: URL) async throws {
        let tracks: [GPX.Track] = try await Task.detached { [gpxParser] in
            try gpxParser.parse(contentsOf: url)
        }.value
        guard !tracks.isEmpty else { throw LoadError.noTracksInFile }
        let newEntries = tracks.map { LibraryEntry(track: $0, url: url) }
        for (entry, track) in zip(newEntries, tracks) {
            cache[entry.source] = runParser.run(from: track)
        }
        entries.insert(contentsOf: newEntries, at: 0)
    }

    // MARK: - Run Loading

    /// Returns the parsed `Run` for the given source, fetching and caching on first access.
    ///
    public func loadRun(source: LibraryEntry.Source) async throws -> Run {
        if let cached = cache[source] { return cached }

        let track: GPX.Track
        switch source {
        case .strava(let activity):
            track = try await stravaClient.track(for: activity)
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
        cache[source] = run
        return run
    }

    /// Convenience wrapper — loads the run for the given entry's source.
    ///
    public func loadRun(for entry: LibraryEntry) async throws -> Run {
        try await loadRun(source: entry.source)
    }

    // MARK: - Delete

    /// Removes the given entry from the library.
    ///
    public func delete(_ entry: LibraryEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    // MARK: - Private

    private func fetchPage() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let activities = try await stravaClient.activities(page: currentPage, perPage: perPage)
            let runs = activities.filter(\.isRun).map(LibraryEntry.init(activity:))
            entries.append(contentsOf: runs)
            if activities.count < perPage {
                hasReachedEnd = true
            } else {
                currentPage += 1
            }
        } catch {
            // Network failures are surfaced via `isLoading` dropping to false;
            // callers can retry via `loadNextPage()`.
        }
    }
}
