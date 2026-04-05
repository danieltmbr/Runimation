import Foundation

/// Reads a `.runi` file from disk, decodes it, and inserts it into the run library.
///
/// Handles security-scoped resource access internally, so callers only need to
/// pass the URL as received from `onOpenURL` or a file picker.
///
/// Inject via `.library(_:)` and access in views with:
/// ```swift
/// @Environment(\.importDocument) private var importDocument
/// let record = try importDocument(url)
/// ```
///
struct ImportDocumentAction {

    private let body: @MainActor (URL) throws -> RunRecord

    init(_ body: @escaping @MainActor (URL) throws -> RunRecord) {
        self.body = body
    }

    init() {
        self.init { _ in .sedentary }
    }

    @MainActor
    init(library: RunLibrary) {
        self.init { url in
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(RuniDocument.self, from: data)
            return try library.importRuniDocument(document)
        }
    }

    @MainActor
    func callAsFunction(_ url: URL) throws -> RunRecord {
        try body(url)
    }
}
