import Foundation

/// Lightweight identifier for `NavigationStack` path serialization.
///
/// Decouples navigation state from the `RunRecord` model object.
/// Resolves to a `RunRecord` via `RunLibrary.record(for:)` at the destination.
///
struct RunEntry: Hashable {
    let id: UUID
}
