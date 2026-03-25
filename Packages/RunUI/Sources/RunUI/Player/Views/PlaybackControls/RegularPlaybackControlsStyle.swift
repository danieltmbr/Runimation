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

            DurationMenu()
                .labelStyle(.iconOnly)
                .font(.headline)
                .buttonStyle(.plain)
        }
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
                .labelStyle(.iconOnly)
            PlayToggle()
                .labelStyle(.iconOnly)
                .font(.title)
            LoopToggle()
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
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
    
    private var displayProgress: Double {
        isDragging ? localProgress : progress
    }

    let isHovering: Bool

    @PlayerState(\.progress.metrics)
    private var progress

    @PlayerState(\.run.metrics)
    private var run

    @Environment(\.seek)
    private var seek

    @State
    private var isDragging = false

    @State
    private var localProgress: Double = 0

    var body: some View {
        VStack {
            Spacer()
            timeLabels
                .opacity(isHovering ? 1 : 0)

//            ProgressSlider()
//                .sliderThumbVisibility(isHovering ? .visible : .hidden)
//                .tint(isHovering ? .accentColor : .secondary)
            
            progressBar
                .frame(height: isHovering ? 6 : 2)
        }
        .allowsHitTesting(isHovering)
        .onChange(of: progress, initial: true) { _, newValue in
            guard !isDragging else { return }
            localProgress = newValue
        }
    }

    // MARK: - Subviews

    /// Elapsed (leading) and remaining (trailing) time labels shown on hover.
    private var timeLabels: some View {
        HStack {
            ElapsedTimeLabel(progress: displayProgress)
            Spacer()
            RemainingTimeLabel(progress: displayProgress)
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    /// Single progress bar — thin at rest, thicker and scrubbable on hover.
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.primary.opacity(0.15))
                Capsule()
                    .fill(.primary)
                    .frame(width: geo.size.width * displayProgress)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        localProgress = max(0, min(1, value.location.x / geo.size.width))
                    }
                    .onEnded { _ in
                        isDragging = false
                        seek(to: localProgress)
                    }
            )
        }
    }
}
