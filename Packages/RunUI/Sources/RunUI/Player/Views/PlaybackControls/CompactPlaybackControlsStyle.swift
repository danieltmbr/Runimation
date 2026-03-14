import SwiftUI

/// Minimal playback controls for the tab bar accessory on iOS.
///
/// Displays Rewind, Play/Pause, and Loop as small icons with equal spacing.
/// A translucent `PlayerProgressBar` creeps across the background from leading
/// to trailing as the animation plays, giving a low-key sense of progress.
///
public struct CompactPlaybackControlsStyle: PlaybackControlsStyle {
    public func makeBody() -> some View {
        CompactPlaybackControls()
    }
}

// MARK: - Layout

private struct CompactPlaybackControls: View {

    var body: some View {
        HStack {
            Spacer()
            RewindButton()
                .imageScale(.small)
            Spacer()
            PlayToggle()
                .imageScale(.large)
            Spacer()
            LoopToggle()
                .imageScale(.small)
            Spacer()
        }
        .labelStyle(.iconOnly)
        .padding(.vertical, 14)
        .foregroundStyle(.primary)
        .background(alignment: .leading) {
            PlayerProgressBar()
                .opacity(0.5)
                .allowsHitTesting(false)
        }
    }
}
