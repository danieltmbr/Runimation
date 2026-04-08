import AuthenticationServices
import CoreKit
import Foundation
#if os(macOS)
import AppKit
#endif

/// Manages Strava authentication and data fetching.
///
/// `StravaClient` is a pure StravaKit type — it has no dependency on RunKit.
/// Conformance to `ActivityTracker` is declared in the app layer so the
/// package dependency graph stays acyclic (App → RunKit, App → StravaKit;
/// StravaKit → CoreKit only).
///
/// ## Usage
/// ```swift
/// let client = StravaClient()
/// let activities = try await client.stravaActivities(before: nil)
/// let points = try await client.trackPoints(for: activities[0].id)
/// ```
///
@MainActor @Observable
public final class StravaClient {

    // MARK: - Public State

    /// True when a valid token is stored in the Keychain.
    public private(set) var isAuthenticated: Bool = false

    /// True while a network request is in flight.
    public private(set) var isLoading: Bool = false

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

    /// Opens the Strava authorization flow.
    ///
    /// On iOS, `anchor` is the presenting `UIWindow` for `ASWebAuthenticationSession`.
    /// On macOS, `anchor` is unused — auth opens in the system browser via `.onOpenURL`.
    ///
    public func connect(from anchor: ASPresentationAnchor?) async throws {
        #if os(macOS)
        try await authenticateViaBrowser()
        #else
        guard let anchor else { return }
        try await authenticateViaSession(presentingFrom: anchor)
        #endif
    }

    /// Removes the stored token and marks the client as unauthenticated.
    public func disconnect() {
        StravaToken.delete()
        token = nil
        isAuthenticated = false
    }

    #if os(macOS)
    /// Resolves a pending Strava OAuth flow with the callback URL the system delivered.
    ///
    /// Call this from `.onOpenURL` in the root view so the `connect(from:)` continuation
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
    #endif

    // MARK: - Data

    /// Fetches the authenticated athlete's run activities, newest first.
    ///
    /// Pass `nil` for the first page. Pass the oldest date from the previous
    /// result as `before` for subsequent pages (cursor-based pagination).
    /// An empty array means all pages have been fetched.
    ///
    public func stravaActivities(before: Date?) async throws -> [StravaActivity] {
        var params: [String: String] = ["per_page": "30"]
        if let before {
            params["before"] = "\(Int(before.timeIntervalSince1970))"
        }
        isLoading = true
        defer { isLoading = false }
        let data = try await fetch(path: "/api/v3/athlete/activities", params: params)
        return try activityDecoder.decode([StravaActivity].self, from: data)
    }

    /// Fetches GPS track points for the given Strava activity ID.
    public func trackPoints(for activityID: Int) async throws -> [GPX.Point] {
        let data = try await fetch(
            path: "/api/v3/activities/\(activityID)/streams",
            params: [
                "keys": "latlng,altitude,time,heartrate,cadence",
                "key_by_type": "true",
            ]
        )
        let streams = try streamDecoder.decode(StravaStreams.self, from: data)
        return StravaTrackMaker.points(from: streams)
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

    // MARK: - Private Auth

    #if os(macOS)
    private func authenticateViaBrowser() async throws {
        let auth = StravaAuth(clientID: clientID, clientSecret: clientSecret)
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
    #else
    private func authenticateViaSession(presentingFrom anchor: ASPresentationAnchor) async throws {
        let auth = StravaAuth(clientID: clientID, clientSecret: clientSecret)
        let newToken = try await auth.authenticate(presentingFrom: anchor)
        newToken.save()
        token = newToken
        isAuthenticated = true
    }
    #endif
}
