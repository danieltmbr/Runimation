import SwiftUI

/// A subtle tappable label showing the current playback duration that opens a
/// menu for selecting one of the four duration presets.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct DurationMenu: View {

    @PlayerState(\.duration)
    private var duration

    var body: some View {
        Menu {
            ForEach(RunPlayer.Duration.all) { option in
                Button(option.label) {
                    duration = option
                }
            }
        } label: {
            Text(duration.label)
                .font(.caption.monospacedDigit())
        }
    }
}
