import SwiftUI
import RunKit

/// A row that summarises the active transformer chain and navigates to
/// `TransformerListView` for editing.
///
/// Place inside a `NavigationStack` (provided by `CustomisationPanel`).
///
public struct TransformerListButton: View {

    @PlayerState(\.transformers)
    private var transformers

    public init() {}

    public var body: some View {
        NavigationLink {
            TransformerListView()
        } label: {
            LabeledContent("Transformers", value: summary)
        }
    }

    // MARK: - Private

    private var summary: String {
        guard !transformers.isEmpty else { return "None" }
        return transformers.map(\.label).joined(separator: " → ")
    }
}
