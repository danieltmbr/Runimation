import SwiftUI
import RunKit

/// A button that stops playback and resets progress to zero.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct StopButton: View {

    @Environment(\.stop)
    private var stop

    public var body: some View {
        Button("Stop", systemImage: "stop.fill") {
            stop()
        }
    }
}
