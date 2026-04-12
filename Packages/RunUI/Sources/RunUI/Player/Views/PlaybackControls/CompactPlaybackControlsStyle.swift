import SwiftUI

/// Minimal playback controls for compact size class (iPhone portrait) bottom bar.
///
/// Displays the run name on the leading side and a Play/Pause toggle on the
/// trailing side. A translucent `PlayerProgressBar` creeps across the background
/// from leading to trailing as the animation plays, giving a low-key sense of
/// progress without taking up additional space.
///
public struct CompactPlaybackControlsStyle: PlaybackControlsStyle {
    public func makeBody() -> some View {
        CompactPlaybackControls()
    }
}

// MARK: - Layout

private struct CompactPlaybackControls: View {

    @Player(\.run.metrics)
    private var run

    var body: some View {
        HStack {
            PlayToggle()
                .imageScale(.large)
                .labelStyle(.iconOnly)
                .padding(.horizontal)

            Text(run.name)
                .lineLimit(2)
                .truncationMode(.tail)
            
            Spacer()
        }
        .padding(.horizontal)
        .foregroundStyle(.primary)
        .background(alignment: .leading) {
            PlayerProgressBar()
                .opacity(0.5)
                .allowsHitTesting(false)
                .mask {
                    Capsule()
                }
        }
    }
}
