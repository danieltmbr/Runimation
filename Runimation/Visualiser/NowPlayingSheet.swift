import RunUI
import SwiftUI

/// "Now Playing" sheet that opens when the compact playback bar is tapped on iOS.
///
/// Displays run info at the top and the full panel playback controls below.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct NowPlayingSheet: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PlayerRunInfoView()
            PlaybackControls()
                .playbackControlsStyle(.panel)
        }
        .padding()
        .padding(.horizontal)
    }
}
