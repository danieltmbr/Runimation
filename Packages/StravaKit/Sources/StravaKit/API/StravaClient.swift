import AuthenticationServices
import CoreKit
import Foundation
#if os(macOS)
import AppKit
#endif

/// Manages Strava authentication and data fetching.
///
/// Create one instance and inject it into the SwiftUI environment via `.environment(stravaClient)`.
/// All state changes happen on the main actor to support `@Observable` and SwiftUI bindings.
///
/// ## Usage
/// ```swift
/// let client = StravaClient()
/// try await client.authenticate(presentingFrom: anchor)
/// let activities = try await client.activities()
/// let track = try await client.track(for: activities[0].id)
/// try await player.setRun(track)
/// ```
///
@MainActor @Observable
public final class StravaClient {

    // MARK: - Public State

    /// True when a valid token is stored in the Keychain.
    public private(set) var isAuthenticated: Bool = false

    // MARK: - Private

    #if os(macOS)
    /// Stores the continuation awaiting the OAuth callback URL delivered via `onOpenURL`.
    private var pendingAuthContinuation: CheckedContinuation<String, Error>?
    #endif

    private let clientID: String
    
    private let clientSecret: String

    private var token: StravaToken?

    private let urlSession = URLSession.shared
    
    private let activityDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let streamDecoder = JSONDecoder()

    // MARK: - Init

    public init() {
        let info = Bundle.main.infoDictionary
        clientID = info?["STRAVA_CLIENT_ID"] as? String ?? ""
        clientSecret = info?["STRAVA_CLIENT_SECRET"] as? String ?? ""
        token = StravaToken.load()
        isAuthenticated = token != nil
    }

    // MARK: - Authentication

    #if os(macOS)
    /// Opens the system browser for Strava authorization.
    ///
    /// The flow completes when the app receives the OAuth callback URL.
    /// Wire up `handleCallbackURL(_:)` via `.onOpenURL` in the root view.
    ///
    public func authenticate() async throws {
        let auth = StravaAuth(clientID: clientID, clientSecret: clientSecret)
        // Cancel any previously abandoned auth attempt.
        pendingAuthContinuation?.resume(throwing: CancellationError())
        let code = try await withCheckedThrowingContinuation { continuation in
            pendingAuthContinuation = continuation
            NSWorkspace.shared.open(auth.authURL)
        }
        pendingAuthContinuation = nil
        let newToken = try await auth.exchangeCode(code)
        newToken.save()
        token = newToken
        isAuthenticated = true
    }

    /// Resolves a pending Strava OAuth flow with the callback URL the system delivered.
    ///
    /// Call this from `.onOpenURL` in the root view so the `authenticate()` continuation
    /// can resume once the browser redirects back to the app.
    ///
    public func handleCallbackURL(_ url: URL) {
        guard let code = StravaAuth.extractCode(from: url) else {
            pendingAuthContinuation?.resume(throwing: StravaError.missingAuthCode)
            pendingAuthContinuation = nil
            return
        }
        pendingAuthContinuation?.resume(returning: code)
        pendingAuthContinuation = nil
    }
    #else
    /// Opens the Strava authorization page and exchanges the result for a token.
    ///
    /// The token is stored in the Keychain and persists across launches.
    ///
    public func authenticate(presentingFrom anchor: ASPresentationAnchor) async throws {
        let auth = StravaAuth(clientID: clientID, clientSecret: clientSecret)
        let newToken = try await auth.authenticate(presentingFrom: anchor)
        newToken.save()
        token = newToken
        isAuthenticated = true
    }
    #endif

    /// Removes the stored token and marks the client as unauthenticated.
    public func signOut() {
        StravaToken.delete()
        token = nil
        isAuthenticated = false
    }

    // MARK: - Data

    /// Fetches the authenticated athlete's activities, newest first.
    ///
    /// - Parameters:
    ///   - page: 1-based page index (default 1).
    ///   - perPage: Results per page, max 200 (default 30).
    ///
    public func activities(page: Int = 1, perPage: Int = 30) async throws -> [StravaActivity] {
        let data = try await fetch(
            path: "/api/v3/athlete/activities",
            params: ["page": "\(page)", "per_page": "\(perPage)"]
        )
        return try activityDecoder.decode([StravaActivity].self, from: data)
    }

    /// Fetches stream data for `activityID` and converts it to a `GPX.Track`
    /// ready for loading into `RunPlayer.setRun(_:)`.
    ///
    public func track(for activityID: Int) async throws -> GPX.Track {
        let data = try await fetch(
            path: "/api/v3/activities/\(activityID)/streams",
            params: [
                "keys": "latlng,altitude,time,heartrate,cadence",
                "key_by_type": "true",
            ]
        )
        let streams = try streamDecoder.decode(StravaStreams.self, from: data)
        return StravaTrackMaker.make(from: streams)
    }

    // MARK: - Private Networking

    private func fetch(path: String, params: [String: String] = [:]) async throws -> Data {
        let currentToken = try await freshToken()
        var components = URLComponents(string: "https://www.strava.com\(path)")!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(currentToken.accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw StravaError.apiError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    /// Returns the current token, refreshing it first if it is about to expire.
    private func freshToken() async throws -> StravaToken {
        guard let current = token else { throw StravaError.notAuthenticated }
        if !current.isExpired { return current }
        let refreshed = try await refresh(expiredToken: current)
        refreshed.save()
        token = refreshed
        return refreshed
    }

    private func refresh(expiredToken: StravaToken) async throws -> StravaToken {
        var request = URLRequest(url: URL(string: "https://www.strava.com/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": expiredToken.refreshToken,
        ]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(StravaToken.self, from: data)
    }
}
