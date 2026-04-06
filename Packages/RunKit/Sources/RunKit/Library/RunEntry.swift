import Foundation

/// Lightweight identifier for `NavigationStack` path serialization.
///
/// Decouples navigation state from the persistence model.
/// Resolves to track data via `RunLibrary.loadRun(for:)` at the destination.
///
public struct RunEntry: Hashable, Sendable {
    public let id: UUID

    public init(id: UUID) {
        self.id = id
    }
}
