import CoreKit
import Foundation
import RunKit

/// Parses a local file and imports the resulting track(s) into the library.
///
/// Handles GPX files. Fires-and-forgets; errors are silently discarded
/// because import failures are surfaced by the empty state of the library.
///
/// Inject via `.library(_:)` and access in views with:
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
        let gpxParser = GPX.Parser()
        self.init { url in
            Task {
                let didStart = url.startAccessingSecurityScopedResource()
                defer { if didStart { url.stopAccessingSecurityScopedResource() } }
                guard let tracks = try? gpxParser.parse(contentsOf: url) as [GPX.Track],
                      !tracks.isEmpty else { return }
                for track in tracks {
                    library.importTrack(
                        name: track.name,
                        date: track.date ?? Date(),
                        points: track.points,
                        source: .file(url: url)
                    )
                }
            }
        }
    }

    @MainActor
    func callAsFunction(_ url: URL) { body(url) }
}
