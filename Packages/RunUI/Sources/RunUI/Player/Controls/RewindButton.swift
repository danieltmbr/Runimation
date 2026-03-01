import SwiftUI
import RunKit

/// A button that seeks to the beginning of the animation without affecting
/// the current playing/paused state.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct RewindButton: View {

    @Environment(\.seek)
    private var seek
    
    public init() {}

    public var body: some View {
        Button("Rewind", systemImage: "backward.end.fill") {
            seek(to: 0)
        }
    }
}
