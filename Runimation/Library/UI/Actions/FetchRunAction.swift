import Foundation
import RunKit

/// Fetches the `Run` for a given `LibraryEntry.Source` from the library cache,
/// loading from the source's origin on first access.
///
/// The core closure operates on `Source` directly. A convenience overload
/// accepts a `LibraryEntry` and forwards its source.
///
/// Unlike fire-and-forget actions, this one is `async throws` — callers
/// `await` the result and handle errors themselves.
///
/// Note: `\.fetchRun` is distinct from the player's `\.loadRun` — this action
/// reads a run from the library; the player's action loads a run into the player.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.fetchRun) private var fetchRun
/// let run = try await fetchRun(entry)
/// let run = try await fetchRun(.strava(activity: activity))
/// ```
///
struct FetchRunAction {

    private let body: @MainActor (LibraryEntry.Source) async throws -> Run

    init(_ body: @escaping @MainActor (LibraryEntry.Source) async throws -> Run) {
        self.body = body
    }

    /// Default no-op — always throws. Replaced by the real action when
    /// `.library(_:player:)` is applied to the view hierarchy.
    ///
    init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { source in
            try await library.loadRun(source: source)
        }
    }

    @MainActor
    func callAsFunction(_ source: LibraryEntry.Source) async throws -> Run {
        try await body(source)
    }

    @MainActor
    func callAsFunction(_ entry: LibraryEntry) async throws -> Run {
        try await body(entry.source)
    }

    // MARK: - Errors

    private struct UnboundError: LocalizedError {
        var errorDescription: String? { "No run library is available in the current environment." }
    }
}
