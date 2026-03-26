import Foundation
import RunKit

/// Loads a `LibraryEntry`'s track from the library and starts playback on the player.
///
/// Fetches from the entry's source if not already cached, then calls the
/// optional `onPlayed` closure on success.
///
/// Inject via `.library(_:player:)` and access in views with:
/// ```swift
/// @Environment(\.playEntry) private var playEntry
/// playEntry(entry)
/// playEntry(entry) { showLibrary = false }
/// ```
///
struct PlayEntryAction {

    private let body: @MainActor (LibraryEntry, @escaping @MainActor () -> Void) -> Void

    init(_ body: @escaping @MainActor (LibraryEntry, @escaping @MainActor () -> Void) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    init(library: RunLibrary, player: RunPlayer) {
        self.init { entry, onPlayed in
            Task {
                guard let run = try? await library.loadRun(for: entry) else { return }
                try? await player.setRun(run)
                onPlayed()
            }
        }
    }

    @MainActor
    func callAsFunction(_ entry: LibraryEntry, onPlayed: @escaping @MainActor () -> Void = {}) {
        body(entry, onPlayed)
    }
}
