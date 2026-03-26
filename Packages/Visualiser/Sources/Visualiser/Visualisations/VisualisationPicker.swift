import SwiftUI

/// A row that shows the active visualisation name and navigates to `VisualisationList`
/// for selection.
///
/// Place inside a `NavigationStack` (provided by `CustomisationPanel`).
/// Switching to a different visualisation resets it to a fresh default instance.
///
public struct VisualisationPicker: View {

    /// Stored directly to avoid `@Binding` property-wrapper synthesis issues
    /// with existential types. `Binding.wrappedValue` has a `nonmutating` setter,
    /// so reads and writes work correctly on a `let` stored property.
    private let visualisation: Binding<any Visualisation>

    public init(visualisation: Binding<any Visualisation>) {
        self.visualisation = visualisation
    }

    public var body: some View {
        NavigationLink {
            VisualisationList(visualisation: visualisation)
        } label: {
            Text(visualisation.wrappedValue.label)
        }
    }
}
