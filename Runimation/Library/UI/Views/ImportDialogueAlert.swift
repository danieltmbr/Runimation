import RunKit
import RunUI
import SwiftUI

/// Presents a "Save to Library?" confirmation alert when a `.runi` file has been
/// imported into a viewer window.
///
/// Reads `importedItem` from `NavigationModel` and `deleteRun` from the
/// environment — no parameters needed. Apply once at the window root:
/// ```swift
/// RuniView()
///     .importDialogue()
/// ```
///
private struct ImportDialogueAlert: ViewModifier {

    @NavigationState(\.importedItem)
    private var importedItem

    @Environment(\.deleteRun)
    private var deleteRun

    func body(content: Content) -> some View {
        content
            .alert(
                "Save to Library?",
                isPresented: Binding(
                    get: { importedItem != nil },
                    set: { if !$0 { importedItem = nil } }
                )
            ) {
                Button("Save") {
                    importedItem = nil
                }
                Button("Remove", role: .destructive) {
                    if let item = importedItem { deleteRun(item) }
                    importedItem = nil
                }
            } message: {
                if let item = importedItem {
                    Text("Keep \(item.name) in your library?")
                }
            }
    }
}

extension View {
    func importDialogue() -> some View {
        modifier(ImportDialogueAlert())
    }
}
