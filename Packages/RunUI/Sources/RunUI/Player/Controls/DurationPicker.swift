import SwiftUI
import RunKit

/// A picker for selecting the playback duration preset.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct DurationPicker: View {

    @PlayerState(\.duration)
    private var duration

    public init() {}

    public var body: some View {
        Picker("Duration", selection: $duration) {
            ForEach(RunPlayer.Duration.all) { option in
                Text(option.label).tag(option)
            }
        }
    }
}
