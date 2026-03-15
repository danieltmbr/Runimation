import AuthenticationServices
import Foundation

/// Performs the Strava OAuth2 authorization code flow.
///
/// Provides the shared steps — building the auth URL, extracting the callback
/// code, and exchanging it for a token — used by `StravaClient` on all platforms.
/// The browser interaction itself is platform-specific and handled in `StravaClient`.
///
@MainActor
struct StravaAuth {

    let clientID: String
    let clientSecret: String

    private let redirectURI = "runimation://oauth/strava"

    // MARK: - Shared

    var authURL: URL {
        var components = URLComponents(string: "https://www.strava.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:read_all"),
        ]
        return components.url!
    }

    static func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    func exchangeCode(_ code: String) async throws -> StravaToken {
        var request = URLRequest(url: URL(string: "https://www.strava.com/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code",
        ]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(StravaToken.self, from: data)
    }

    // MARK: - iOS / iPadOS

    #if !os(macOS)
    /// Runs the full OAuth2 flow via `ASWebAuthenticationSession`.
    func authenticate(presentingFrom anchor: ASPresentationAnchor) async throws -> StravaToken {
        let code = try await requestAuthCode(from: anchor)
        return try await exchangeCode(code)
    }

    private func requestAuthCode(from anchor: ASPresentationAnchor) async throws -> String {
        // Hold a strong reference so the session isn't deallocated before its callback fires.
        var sessionRef: ASWebAuthenticationSession?
        defer { sessionRef = nil }

        return try await withCheckedThrowingContinuation { continuation in
            let contextProvider = AnchorProvider(anchor: anchor)
            // Capture contextProvider in the completion handler — presentationContextProvider
            // is a weak reference, so this closure is the only thing keeping it alive.
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "runimation"
            ) { [contextProvider] callbackURL, error in
                _ = contextProvider
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url = callbackURL,
                      let code = Self.extractCode(from: url) else {
                    continuation.resume(throwing: StravaError.missingAuthCode)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = true
            sessionRef = session
            session.start()
        }
    }
    #endif
}

// MARK: - Presentation Context Provider (iOS / iPadOS only)

#if !os(macOS)
/// Bridges the `ASPresentationAnchor` into the `ASWebAuthenticationPresentationContextProviding`
/// protocol required by `ASWebAuthenticationSession`.
///
private final class AnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {

    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor
    }
}
#endif
