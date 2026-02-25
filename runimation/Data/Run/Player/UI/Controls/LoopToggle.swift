import SwiftUI

/// A button that toggles looping on and off.
///
/// Dims when loop is inactive to signal the off state without hiding the control.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
struct LoopToggle: View {

    @PlayerState(\.loop)
    private var loop

    var body: some View {
        Button("Loop", systemImage: "repeat") {
            loop.toggle()
        }
        .foregroundStyle(loop ? .primary : .tertiary)
    }
}
