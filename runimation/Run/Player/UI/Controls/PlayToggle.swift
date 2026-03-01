import SwiftUI

/// A button that toggles between play and pause.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayToggle: View {
    
    @PlayerState(\.runs)
    private var runs

    @PlayerState(\.isPlaying)
    private var isPlaying

    @Environment(\.togglePlay)
    private var togglePlay

    var body: some View {
        Button(
            isPlaying ? "Pause" : "Play",
            systemImage: isPlaying ? "pause.fill" : "play.fill"
        ) {
            togglePlay()
        }
        .disabled(runs == nil)
    }
}
