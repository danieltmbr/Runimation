import SwiftUI

/// A picker for selecting the playback duration preset.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct DurationPicker: View {

    @PlayerState(\.duration)
    private var duration

    var body: some View {
        Picker("Duration", selection: $duration) {
            ForEach(RunPlayer.Duration.all) { option in
                Text(option.label).tag(option)
            }
        }
    }
}
