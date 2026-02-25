import SwiftUI

/// A button that stops playback and resets progress to zero.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct StopButton: View {

    @Environment(\.stop)
    private var stop

    var body: some View {
        Button("Stop", systemImage: "stop.fill") {
            stop()
        }
    }
}
