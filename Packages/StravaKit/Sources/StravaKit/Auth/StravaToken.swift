import Foundation
import Security

/// Represents a Strava OAuth2 token pair.
///
/// Strava returns `expires_at` as a Unix timestamp, so the `init(from:)` decoder
/// handles that conversion. The token can be persisted to and loaded from the
/// system Keychain.
///
struct StravaToken: Codable, Sendable {

    let accessToken: String

    let refreshToken: String

    /// Absolute expiry time, derived from Strava's Unix `expires_at` field.
    let expiresAt: Date

    /// True when the token will expire within the next 60 seconds.
    var isExpired: Bool {
        expiresAt < Date().addingTimeInterval(60)
    }
}

// MARK: - Codable

extension StravaToken {

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        let timestamp = try container.decode(TimeInterval.self, forKey: .expiresAt)
        expiresAt = Date(timeIntervalSince1970: timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(expiresAt.timeIntervalSince1970, forKey: .expiresAt)
    }
}

// MARK: - Keychain

extension StravaToken {

    private static let keychainAccount = "me.tmbr.runimation.strava-token"

    /// Loads a persisted token from the system Keychain, or `nil` if none exists.
    static func load() -> StravaToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(StravaToken.self, from: data)
    }

    /// Persists the token to the system Keychain, replacing any existing entry.
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Removes the persisted token from the Keychain.
    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
