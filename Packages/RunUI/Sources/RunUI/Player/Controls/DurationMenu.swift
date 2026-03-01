import SwiftUI
import RunKit

/// A subtle tappable label showing the current playback duration that opens a
/// menu for selecting one of the four duration presets.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct DurationMenu: View {

    @PlayerState(\.duration)
    private var duration

    public var body: some View {
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
