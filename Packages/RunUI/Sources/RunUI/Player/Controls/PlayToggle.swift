import SwiftUI
import RunKit

/// A button that toggles between play and pause.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct PlayToggle: View {
    
    @Player(\.run.animation)
    private var run

    @Player(\.isPlaying)
    private var isPlaying

    @Environment(\.togglePlay)
    private var togglePlay
    
    public init() {}

    public var body: some View {
        Button {
            togglePlay()
        } label: {
            Label {
                Text(isPlaying ? "Pause" : "Play")
            } icon: {
                ZStack {
                    Image(systemName: "play").opacity(0)
                    Image(systemName: isPlaying ? "pause" : "play")
                }
            }
        }
        .contentTransition(.symbolEffect(.replace))
        .symbolVariant(.fill)
        .disabled(run.duration <= 0)
    }
}
