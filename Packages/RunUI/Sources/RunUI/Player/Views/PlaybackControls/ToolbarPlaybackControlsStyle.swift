import SwiftUI

/// Compact inline playback controls for the macOS window toolbar.
///
/// All controls sit in a single horizontal row: transport buttons, a fixed-width
/// progress slider with elapsed time, and a duration picker.
///
public struct ToolbarPlaybackControlsStyle: PlaybackControlsStyle {
    public func makeBody() -> some View {
        ToolbarPlaybackControls()
    }
}

// MARK: - Layout

private struct ToolbarPlaybackControls: View {
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
