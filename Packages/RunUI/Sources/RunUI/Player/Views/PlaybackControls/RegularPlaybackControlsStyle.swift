import SwiftUI

/// Apple Music-style playback controls for regular size class (iPad, Mac) bottom bar.
///
/// Transport buttons (rewind, play, loop) sit on the leading side, run info is centred,
/// and the duration selector sits on the trailing side. A thin progress line sits below
/// the info and cross-fades to a full scrub bar with elapsed/remaining times on hover.
///
public struct RegularPlaybackControlsStyle: PlaybackControlsStyle {
    public func makeBody() -> some View {
        RegularPlaybackControls()
    }
}

// MARK: - Layout

private struct RegularPlaybackControls: View {

    @State
    private var isHovering = false

    var body: some View {
        HStack {
            transportControls

            infoView
                .padding(.horizontal)

            DurationMenu()
                .font(.headline)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .padding(.horizontal)
        .foregroundStyle(.primary)
    }

    /// The overlay fills the RunInfoView's frame so `HoverProgressBar` is naturally
    /// scoped to the info's width — no stretching, no layout change on hover.
    private var infoView: some View {
        RunInfoView()
            .runInfoViewStyle(.compact)
            .blur(radius: isHovering ? 8 : 0)
            .padding(6)
            .overlay {
                HoverProgressBar(isHovering: isHovering)
                    .padding(.bottom, isHovering ? 4 : 1)
            }
            .onHover { isHovering = $0 }
            .animation(.easeInOut(duration: 0.2), value: isHovering)
    }

    private var transportControls: some View {
        HStack(spacing: 8) {
            RewindButton()
            PlayToggle()
                .font(.title)
            LoopToggle()
        }
    }
}

// MARK: - Hover Progress Bar

/// Fills the info overlay frame. In the non-hover state a thin line sits at the bottom.
/// On hover the thin line cross-fades to a scrub column: time labels above, bar below —
/// matching Apple Music's layout where the labels appear over the blurred info text.
///
/// Mirrors the `ProgressSlider` frozen-during-drag pattern: local value is
/// kept in sync with player progress, but freezes while the user drags so
/// the thumb tracks the finger rather than jumping to the player position.
///
private struct HoverProgressBar: View {

    let isHovering: Bool

    var body: some View {
        VStack {
            Spacer()
            timeLabels
                .opacity(isHovering ? 1 : 0)

            ProgressSlider()
                .progressSliderStyle(.minimal)
                .frame(height: isHovering ? 6 : 2)
        }
        .allowsHitTesting(isHovering)
    }

    // MARK: - Subviews

    /// Elapsed (leading) and remaining (trailing) time labels shown on hover.
    private var timeLabels: some View {
        HStack {
            ElapsedTimeLabel()
            Spacer()
            RemainingTimeLabel()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
