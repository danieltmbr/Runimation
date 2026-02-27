import SwiftUI

/// Full-size playback controls for the bottom sheet inspector on iOS.
///
/// Shows a progress slider row (elapsed time, scrubber, duration picker) above
/// a large icon row (Rewind, Play/Pause, Loop).
///
struct RegularPlaybackControlsStyle: PlaybackControlsStyle {
    func makeBody() -> some View {
        RegularPlaybackControls()
    }
}

// MARK: - Layout

private struct RegularPlaybackControls: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ElapsedTimeLabel()
                ProgressSlider()
                    .sliderThumbVisibility(.automatic)
                DurationMenu()
            }
            .padding(.horizontal)

            HStack {
                Spacer()
                RewindButton()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 26, weight: .semibold))
                Spacer()
                PlayToggle()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 46))
                Spacer()
                LoopToggle()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 26, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.primary)
        }
    }
}
