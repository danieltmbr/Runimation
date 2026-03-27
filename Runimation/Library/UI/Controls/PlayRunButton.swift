import RunKit
import SwiftUI

/// A button that loads a `RunRecord` into the player using `NowPlaying.play(_:)`.
///
/// On tap, calls `nowPlaying.play(record)` which handles:
/// - Loading the run from the library (with cache).
/// - Setting it on the player.
/// - Applying or inheriting config.
/// - Marking the record as playing.
///
/// Usage:
/// ```swift
/// PlayRunButton(record, onPlayed: { showLibrary = false }) { record in
///     RunEntryRow(record: record) { ... }
/// }
/// ```
///
struct PlayRunButton<Content: View>: View {

    @NowPlaying
    private var nowPlaying

    let record: RunRecord

    let onPlayed: @MainActor () -> Void

    @ViewBuilder
    let content: (RunRecord) -> Content

    init(
        _ record: RunRecord,
        onPlayed: @escaping @MainActor () -> Void = {},
        @ViewBuilder content: @escaping (RunRecord) -> Content
    ) {
        self.record = record
        self.onPlayed = onPlayed
        self.content = content
    }

    var body: some View {
        Button(action: play) {
            content(record)
        }
    }

    // MARK: - Private

    private func play() {
        Task { @MainActor in
            await nowPlaying.play(record)
            onPlayed()
        }
    }
}
