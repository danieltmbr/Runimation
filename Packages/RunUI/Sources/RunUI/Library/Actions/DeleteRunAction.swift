import RunKit

/// Removes a `RunItem` from the library.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.deleteRun) private var deleteRun
/// deleteRun(item)
/// ```
///
public struct DeleteRunAction {

    private let body: @MainActor (RunItem) -> Void

    public init(_ body: @escaping @MainActor (RunItem) -> Void) {
        self.body = body
    }

    public init() {
        self.init { _ in }
    }

    @MainActor
    public init(library: RunLibrary) {
        self.init { item in library.delete(item) }
    }

    @MainActor
    public func callAsFunction(_ item: RunItem) { body(item) }
}
