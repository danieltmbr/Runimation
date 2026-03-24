import SwiftUI

/// Segmented picker for selecting the active visualisation.
///
/// Shown at the top of the Visualisation inspector panel. Switching to a different
/// visualisation resets it to a fresh default instance — any prior configuration
/// for that type is not preserved between switches.
///
public struct VisualisationPicker: View {

    /// Stored directly to avoid `@Binding` property-wrapper synthesis issues
    /// with existential types. `Binding.wrappedValue` has a `nonmutating` setter,
    /// so reads and writes work correctly on a `let` stored property.
    private let visualisation: Binding<any Visualisation>

    private static let catalog: [any Visualisation] = [Warp(), RunPath()]

    public init(visualisation: Binding<any Visualisation>) {
        self.visualisation = visualisation
    }

    public var body: some View {
        Picker("Visualisation", selection: selectionBinding) {
            ForEach(Self.catalog.indices, id: \.self) { i in
                Text(Self.catalog[i].label).tag(i)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    // MARK: - Private

    /// Maps the current visualisation to its index in `catalog` by label,
    /// and writes a fresh catalog instance back on selection change.
    ///
    private var selectionBinding: Binding<Int> {
        Binding(
            get: { Self.catalog.firstIndex(where: { $0.label == visualisation.wrappedValue.label }) ?? 0 },
            set: { visualisation.wrappedValue = Self.catalog[$0] }
        )
    }
}
