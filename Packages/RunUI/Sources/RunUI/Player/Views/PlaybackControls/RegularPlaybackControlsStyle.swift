import SwiftUI

/// Compact inline playback controls for regular size class (iPad, Mac) bottom bar.
///
/// All controls sit in a single horizontal row: transport buttons, a fixed-width
/// progress slider with elapsed time, and a duration picker.
///
/// Phase 2 will update this to the Apple Music-style layout with run info and
/// a hover-to-scrub progress line.
///
public struct RegularPlaybackControlsStyle: PlaybackControlsStyle {
    public func makeBody() -> some View {
        RegularPlaybackControls()
    }
}

// MARK: - Layout

private struct RegularPlaybackControls: View {
    var body: some View {
        HStack(spacing: 8) {
            RewindButton()
                .labelStyle(.iconOnly)
            PlayToggle()
                .labelStyle(.iconOnly)
            LoopToggle()
                .labelStyle(.iconOnly)
            Divider()
                .frame(height: 16)
            ElapsedTimeLabel()
                .foregroundStyle(.secondary)
            ProgressSlider()
                .frame(width: 160)
            DurationMenu()
        }
        .foregroundStyle(.primary)
    }
}
