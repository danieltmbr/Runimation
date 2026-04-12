import SwiftUI

/// Routes the active visualisation to its GPU canvas view.
///
/// This is the only location where `AnyView` is used for visualisation dispatch.
/// Each visualisation's `canvas(state:binding:)` returns a fully typed view —
/// erasure happens here at the runtime boundary, not inside the protocol.
///
/// Adding a new visualisation type requires no changes here — only to `Visualisation`
/// conformances and `VisualisationPicker.catalog`.
///
public struct VisualiserCanvas: View {

    let state: VisualiserState

    /// Stored directly to avoid `@Binding` property-wrapper synthesis issues
    /// with existential types. `Binding.wrappedValue` has a `nonmutating` setter,
    /// so reads and writes work correctly on a `let` stored property.
    private let visualisation: Binding<any Visualisation>

    public init(
        state: VisualiserState,
        visualisation: Binding<any Visualisation>
    ) {
        self.state = state
        self.visualisation = visualisation
    }

    public var body: some View {
        makeCanvas(for: visualisation.wrappedValue)
    }

    // MARK: - Private

    /// SE-0352 opens `any Visualisation` to the concrete type `V`, allowing a
    /// fully typed `Binding<V>` to be projected and passed to the canvas method.
    /// Returns `AnyView` (not `some View`) so the return type does not depend on
    /// the opened type `V` — a requirement for SE-0352 implicit existential opening.
    /// The force-cast in the getter is safe: `V` was opened from `visualisation`,
    /// so the cast succeeds for the lifetime of this render cycle.
    ///
    private func makeCanvas<V: Visualisation>(for vis: V) -> AnyView {
        AnyView(vis.canvas(state: state, binding: Binding(
            get: { visualisation.wrappedValue as! V },
            set: { visualisation.wrappedValue = $0 }
        )))
    }
}

#Preview {
    VisualiserCanvas(state: .zero, visualisation: .constant(Warp() as any Visualisation))
}
