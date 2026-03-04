import Foundation

/// Errors produced by `StravaClient` and related types.
public enum StravaError: LocalizedError, Sendable {

    /// The user is not authenticated; call `authenticate` first.
    case notAuthenticated

    /// The OAuth2 callback did not contain a `code` parameter.
    case missingAuthCode

    /// The Strava API returned a non-200 HTTP status.
    case apiError(Int)

    /// The API response could not be decoded as expected.
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Strava. Please connect your account."
        case .missingAuthCode:
            return "Authorization failed: no code was returned by Strava."
        case .apiError(let code):
            return "Strava API error (HTTP \(code))."
        case .decodingError(let detail):
            return "Could not read Strava data: \(detail)"
        }
    }
}
