import SwiftUI
import RunKit

/// A picker for selecting the playback duration preset.
///
public struct DurationPicker: View {

    @Binding
    private var duration: RunPlayer.Duration

    public init(duration: Binding<RunPlayer.Duration>) {
        self._duration = duration
    }

    public var body: some View {
        Picker("Duration", systemImage: "timer", selection: $duration) {
            ForEach(RunPlayer.Duration.all) { option in
                Text(option.label).tag(option)
            }
        }
    }
}
