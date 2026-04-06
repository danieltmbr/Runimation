import AuthenticationServices
import CoreKit
import Foundation
import RunKit
import StravaKit
#if os(iOS)
import UIKit
#endif

/// An `ActivityTracker` implementation backed by the Strava API.
///
/// Wraps `StravaClient` and owns all Strava-specific concerns:
/// pagination state, authentication flow, and activity-ID conversion.
///
@MainActor
@Observable
final class StravaTracker: ActivityTracker {

    let id: String = "strava"

    let displayName: String = "Strava"

    var isConnected: Bool { client.isAuthenticated }

    var isLoading: Bool = false

    private let client: StravaClient

    private var currentPage = 1

    private var hasReachedEnd = false

    private let perPage = 30

    // MARK: - Init

    init(client: StravaClient) {
        self.client = client
    }

    // MARK: - Connection

    func connect() async throws {
        #if os(macOS)
        try await client.authenticate()
        #else
        guard let anchor = keyWindow() else { return }
        try await client.authenticate(presentingFrom: anchor)
        #endif
    }

    func disconnect() {
        client.signOut()
    }

    /// Forwards a Strava OAuth callback URL (macOS only).
    ///
    /// Wire up via `.onOpenURL` for the `runimation://` scheme.
    ///
    #if os(macOS)
    func handleCallbackURL(_ url: URL) {
        client.handleCallbackURL(url)
    }
    #endif

    // MARK: - Fetching

    func fetchNext() async throws -> [Activity] {
        guard !hasReachedEnd else { return [] }
        isLoading = true
        defer { isLoading = false }

        let stravaActivities = try await client.activities(page: currentPage, perPage: perPage)
        let runs = stravaActivities.filter(\.isRun)

        if stravaActivities.count < perPage {
            hasReachedEnd = true
        } else {
            currentPage += 1
        }

        return runs.map { activity in
            Activity(
                id: String(activity.id),
                name: activity.name,
                date: activity.startDate,
                distance: activity.distance,
                duration: TimeInterval(activity.movingTime),
                source: ActivitySource(tracker: id, activityID: String(activity.id))
            )
        }
    }

    func resetPagination() {
        currentPage = 1
        hasReachedEnd = false
    }

    // MARK: - Track Data

    func track(for source: ActivitySource) async throws -> GPX.Track {
        guard let activityID = Int(source.activityID) else {
            throw TrackerError.invalidActivityID
        }
        return try await client.track(for: activityID, name: "", date: Date())
    }

    // MARK: - Errors

    enum TrackerError: LocalizedError {
        case invalidActivityID

        var errorDescription: String? {
            "Invalid Strava activity ID."
        }
    }

    // MARK: - Private

    #if os(iOS)
    @MainActor
    private func keyWindow() -> ASPresentationAnchor? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }
    }
    #endif
}
