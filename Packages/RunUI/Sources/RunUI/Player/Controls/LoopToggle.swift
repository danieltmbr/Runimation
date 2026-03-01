import SwiftUI
import RunKit

/// A button that toggles looping on and off.
///
/// Dims when loop is inactive to signal the off state without hiding the control.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct LoopToggle: View {

    @PlayerState(\.loop)
    private var loop

    public var body: some View {
        Button("Loop", systemImage: "repeat") {
            loop.toggle()
        }
        .foregroundStyle(loop ? .primary : .tertiary)
    }
}
