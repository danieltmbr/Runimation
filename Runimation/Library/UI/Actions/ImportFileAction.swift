import Foundation

/// Parses a file at the given URL and prepends the resulting entries to the library.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.importFile) private var importFile
/// importFile(url)
/// ```
///
struct ImportFileAction {

    private let body: @MainActor (URL) -> Void

    init(_ body: @escaping @MainActor (URL) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { url in Task { try? await library.importFile(from: url) } }
    }

    @MainActor
    func callAsFunction(_ url: URL) { body(url) }
}
