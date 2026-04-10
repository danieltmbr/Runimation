import Foundation

/// A lightweight, type-safe identifier for a persisted run.
///
/// Passed to `RunLibrary` operations instead of raw UUIDs, so callers cannot
/// accidentally substitute an unrelated UUID. Use `RunItem.id` directly.
///
/// Mirrors the `TrackerID` pattern — a thin `Hashable, Sendable, Codable`
/// wrapper that can be stored in views and passed to environment actions.
///
public struct RunID: Hashable, Sendable, Codable {

    public let value: UUID

    public init(_ value: UUID = UUID()) {
        self.value = value
    }

    // MARK: - Codable

    /// Encodes as a bare UUID string so `RunItem` navigation paths remain
    /// compatible with a plain `id: UUID` encoding.
    ///
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(UUID.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
