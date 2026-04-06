import CoreKit
import Foundation

/// An external source of run activities (e.g. Strava, HealthKit).
///
/// Each conforming type owns its own authentication state, pagination
/// state, and API communication. The library calls `fetchNext()` /
/// `resetPagination()` without needing to know anything about page
/// numbers or per-page limits.
///
/// Connection management (`connect` / `disconnect`) lives here so
/// RunUI can ship a generic `ConnectToggle` that works for any tracker.
///
@MainActor
public protocol ActivityTracker: AnyObject, Observable {

    /// A stable, unique identifier for this tracker (e.g. `"strava"`).
    var id: String { get }

    /// Human-readable name shown in the UI (e.g. `"Strava"`).
    var displayName: String { get }

    /// Whether the user is currently authenticated with this tracker.
    var isConnected: Bool { get }

    /// True while a network request is in flight.
    var isLoading: Bool { get }

    // MARK: - Connection

    /// Authenticate with the tracker's service.
    ///
    /// Each tracker handles its own auth flow internally
    /// (OAuth web session, HealthKit permission dialog, etc.).
    ///
    func connect() async throws

    /// Sign out and clear any stored credentials.
    func disconnect()

    // MARK: - Fetching

    /// Fetch the next batch of activities.
    ///
    /// Pagination is managed internally. Returns an empty array when
    /// all pages have been fetched. Call `resetPagination()` before
    /// calling `fetchNext()` for a full refresh.
    ///
    func fetchNext() async throws -> [Activity]

    /// Reset internal pagination state so the next `fetchNext()` call
    /// starts from the first page.
    func resetPagination()

    // MARK: - Track Data

    /// Fetch full GPS track data for a specific activity source.
    func track(for source: ActivitySource) async throws -> GPX.Track
}
