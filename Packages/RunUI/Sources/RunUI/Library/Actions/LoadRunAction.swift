import RunKit

/// Loads the `Run` for a given `RunItem` from the library.
///
/// Resolves track data from the cache, local storage, or the original
/// source (remote tracker, bundled file, or local file).
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.loadRun) private var loadRun
/// let run = try await loadRun(item)
/// ```
///
public struct LoadRunAction {

    private let body: @MainActor (RunItem) async throws -> Run

    public init(_ body: @escaping @MainActor (RunItem) async throws -> Run) {
        self.body = body
    }

    public init() {
        self.init { _ in throw UnboundError() }
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { item in
            try await library.load(item, with: [.run]).run!
        }
    }

    @MainActor
    public func callAsFunction(_ item: RunItem) async throws -> Run {
        try await body(item)
    }

    // MARK: - Errors

    private struct UnboundError: Error {
        var errorDescription: String? { "No run library is available in the current environment." }
    }
}
