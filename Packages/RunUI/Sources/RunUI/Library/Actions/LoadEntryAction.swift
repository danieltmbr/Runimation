import RunKit

/// Fetches the `Run` for a given `RunEntry` from the library.
///
/// Resolves track data from the cache, local storage, or the original
/// source (remote tracker, bundled file, or local file).
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.loadEntry) private var loadEntry
/// let run = try await loadEntry(entry)
/// ```
///
public struct LoadEntryAction {

    private let body: @MainActor (RunEntry) async throws -> Run

    public init(_ body: @escaping @MainActor (RunEntry) async throws -> Run) {
        self.body = body
    }

    public init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { entry in try await library.loadRun(for: entry) }
    }

    @MainActor
    public func callAsFunction(_ entry: RunEntry) async throws -> Run {
        try await body(entry)
    }

    // MARK: - Errors

    private struct UnboundError: Error {
        var errorDescription: String? { "No run library is available in the current environment." }
    }
}
