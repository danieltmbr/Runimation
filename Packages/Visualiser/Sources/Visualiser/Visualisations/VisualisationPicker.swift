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
            LabeledContent("Visualisation", value: visualisation.wrappedValue.label)
        }
    }
}

// MARK: - Selection List

/// Full-screen list of available visualisations.
///
/// Displays name and description for each entry. Tapping an item selects it
/// and dismisses the view back to the panel.
///
public struct VisualisationList: View {

    private let visualisation: Binding<any Visualisation>

    private static let catalog: [any Visualisation] = [Warp(), RunPath()]

    @Environment(\.dismiss)
    private var dismiss

    public init(visualisation: Binding<any Visualisation>) {
        self.visualisation = visualisation
    }

    public var body: some View {
        List(Self.catalog.indices, id: \.self) { index in
            let item = Self.catalog[index]
            let isSelected = item.label == visualisation.wrappedValue.label
            Button {
                visualisation.wrappedValue = item
                dismiss()
            } label: {
                LabeledContent {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle("Visualisation")
    }
}
