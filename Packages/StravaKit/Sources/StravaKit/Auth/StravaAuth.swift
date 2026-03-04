import AuthenticationServices
import Foundation

/// Performs the Strava OAuth2 authorization code flow.
///
/// Uses `ASWebAuthenticationSession` to open the Strava authorization page in
/// the system browser, then exchanges the returned code for an access token.
///
@MainActor
struct StravaAuth {

    let clientID: String
    let clientSecret: String

    private let redirectScheme = "runimation"
    private let redirectURI = "runimation://oauth/strava"

    // MARK: - Public

    /// Runs the full OAuth2 flow: opens the browser, waits for the callback,
    /// then exchanges the code for a `StravaToken`.
    ///
    func authenticate(presentingFrom anchor: ASPresentationAnchor) async throws -> StravaToken {
        let code = try await requestAuthCode(from: anchor)
        return try await exchangeCode(code)
    }

    // MARK: - Private

    private var authURL: URL {
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
                callbackURLScheme: redirectScheme
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
            session.prefersEphemeralWebBrowserSession = false
            sessionRef = session
            session.start()
        }
    }

    private func exchangeCode(_ code: String) async throws -> StravaToken {
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

    private static func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }
}

// MARK: - Presentation Context Provider

/// Bridges the `ASPresentationAnchor` into the `ASWebAuthenticationPresentationContextProviding`
/// protocol required by `ASWebAuthenticationSession`.
///
@MainActor
private final class AnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {

    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor
    }
}
