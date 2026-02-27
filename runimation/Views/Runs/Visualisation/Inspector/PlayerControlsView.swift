import SwiftUI

/// The compact player controls shown as a tab bar accessory across all tabs.
///
/// Displays Rewind, Play/Pause, and Loop buttons. A very subtle translucent fill
/// creeps across the background from leading to trailing as the animation plays,
/// giving a low-key sense of progress without a separate UI element.
/// Tapping anywhere outside the three buttons opens the full player sheet.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct PlayerControlsView: View {

    @Binding var showInspector: Bool

    @PlayerState(\.progress)
    private var progress

    var body: some View {
        HStack {
            Spacer()
            RewindButton()
                .labelStyle(.iconOnly)
                .imageScale(.small)
                .buttonStyle(.plain)
            Spacer()
            PlayToggle()
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .buttonStyle(.plain)
            Spacer()
            LoopToggle()
                .labelStyle(.iconOnly)
                .imageScale(.small)
            Spacer()
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 14)
        .background(alignment: .leading) {
            PlayerProgressBar()
                .opacity(0.5)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { showInspector.toggle() }
    }
}
