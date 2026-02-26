import SwiftUI

/// A button that seeks to the beginning of the animation without affecting
/// the current playing/paused state.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct RewindButton: View {

    @Environment(\.seek)
    private var seek

    var body: some View {
        Button("Rewind", systemImage: "backward.end.fill") {
            seek(to: 0)
        }
    }
}
