import RunKit
import SwiftUI

/// A button that loads a `RunItem` into the player using `NowPlaying.play(_:)`.
///
/// On tap, calls `nowPlaying.play(item)` which handles:
/// - Loading the run from the library (with cache).
/// - Setting it on the player.
/// - Applying or inheriting config.
/// - Marking the item as playing.
///
/// Usage:
/// ```swift
/// PlayRunButton(item) { item in
///     RunInfoView(item: item)
/// }
/// ```
///
struct PlayRunButton<Content: View>: View {

    @Environment(\.dismiss)
    private var dismiss

    @NowPlaying
    private var nowPlaying

    let item: RunItem

    @ViewBuilder
    let content: (RunItem) -> Content

    init(
        _ item: RunItem,
        @ViewBuilder content: @escaping (RunItem) -> Content
    ) {
        self.item = item
        self.content = content
    }

    var body: some View {
        Button(action: play) {
            content(item)
        }
    }

    // MARK: - Private

    private func play() {
        Task { @MainActor in
            await nowPlaying.play(item)
            // dismiss()
        }
    }
}
