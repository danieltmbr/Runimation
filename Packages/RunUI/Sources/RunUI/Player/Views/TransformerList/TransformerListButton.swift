import SwiftUI
import RunKit

/// A button row that summarises the active transformer chain
/// and opens `TransformerListView` as a sheet for editing.
///
/// Place inside `DiagnosticsContent` or any form-style container
/// that has a `RunPlayer` in the environment.
///
public struct TransformerListButton: View {

    @PlayerState(\.transformers)
    private var transformers

    @State
    private var showSheet = false
    
    public init() {}

    public var body: some View {
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
        guard !transformers.isEmpty else { return "None" }
        return transformers.map(\.label).joined(separator: " → ")
    }
}
