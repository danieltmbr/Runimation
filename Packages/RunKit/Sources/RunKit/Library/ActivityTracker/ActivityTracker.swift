import AuthenticationServices
import CoreKit
import Foundation

/// An external source of run activities (e.g. Strava, HealthKit).
///
/// Each conforming type owns its own authentication and loading state.
/// Pagination is managed by `RunLibrary`, which passes a `before` cursor
/// so the tracker never needs to track page numbers internally.
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
    /// On iOS, `anchor` is the presenting `UIWindow` for the OAuth web session.
    /// On macOS, `anchor` is unused — auth opens in the system browser.
    /// Other tracker types (e.g. HealthKit) may ignore `anchor` entirely.
    ///
    func connect(from anchor: ASPresentationAnchor?) async throws

    /// Sign out and clear any stored credentials.
    func disconnect()

    // MARK: - Fetching

    /// Fetch a page of activities ending before `before`.
    ///
    /// Pass `nil` for the first page (newest activities). Pass the oldest
    /// date from the previous page for subsequent pages. Returns an empty
    /// array when no more activities are available.
    ///
    func activities(before: Date?) async throws -> [Activity]

    // MARK: - Track Data

    /// Fetch full GPS track points for a specific activity source.
    func trackPoints(for source: ActivitySource) async throws -> [GPX.Point]
}
