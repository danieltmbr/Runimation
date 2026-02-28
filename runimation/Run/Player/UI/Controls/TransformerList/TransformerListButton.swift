import SwiftUI

/// A button row that summarises the active transformer chain
/// and opens `TransformerListView` as a sheet for editing.
///
/// Place inside `DiagnosticsContent` or any form-style container
/// that has a `RunPlayer` in the environment.
///
struct TransformerListButton: View {

    @PlayerState(\.selectedTransformers)
    private var selectedTransformers

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            LabeledContent("Transformers", value: summary)
        }
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                TransformerListView()
            }
        }
    }

    // MARK: - Private

    private var summary: String {
        guard !selectedTransformers.isEmpty else { return "None" }
        return selectedTransformers.map(\.label).joined(separator: " → ")
    }
}
