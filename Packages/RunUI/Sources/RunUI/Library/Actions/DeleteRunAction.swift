import RunKit

/// Removes a `RunEntry` from the library.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.deleteRun) private var deleteRun
/// deleteRun(entry)
/// ```
///
public struct DeleteRunAction {

    private let body: @MainActor (RunEntry) -> Void

    public init(_ body: @escaping @MainActor (RunEntry) -> Void) {
        self.body = body
    }

    public init() {
        self.init { _ in }
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { entry in library.delete(entry) }
    }

    @MainActor
    public func callAsFunction(_ entry: RunEntry) { body(entry) }
}
