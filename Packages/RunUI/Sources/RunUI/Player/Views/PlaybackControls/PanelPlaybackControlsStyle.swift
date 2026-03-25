import SwiftUI

/// Full-size playback controls for the bottom sheet inspector on iOS.
///
/// Shows a progress slider row (elapsed time, scrubber, duration picker) above
/// a large icon row (Rewind, Play/Pause, Loop).
///
public struct PanelPlaybackControlsStyle: PlaybackControlsStyle {
    public func makeBody() -> some View {
        PanelPlaybackControls()
    }
}

// MARK: - Layout

private struct PanelPlaybackControls: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                RewindButton()
                    .labelStyle(.iconOnly)
                    .font(.headline)
                Spacer()
                PlayToggle()
                    .labelStyle(.iconOnly)
                    .font(.largeTitle)
                Spacer()
                LoopToggle()
                    .labelStyle(.iconOnly)
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(.primary)

            VStack(spacing: 8) {
                ProgressSlider()
                    .sliderThumbVisibility(.automatic)
                
                HStack(alignment: .top) {
                    ElapsedTimeLabel()
                        .font(.caption)
                    Spacer()
                    DurationMenu()
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.primary)
                        .font(.headline)
                    Spacer()
                    RemainingTimeLabel()
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}
