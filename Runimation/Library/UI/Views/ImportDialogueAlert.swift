import RunUI
import SwiftUI

/// Presents a "Save to Library?" confirmation alert when a `.runi` file has been
/// imported into a viewer window.
///
/// Reads `importedRecord` from `NavigationModel` and `deleteRun` from the
/// environment — no parameters needed. Apply once at the window root:
/// ```swift
/// RuniView()
///     .importSaveAlert()
/// ```
///
private struct ImportDialogueAlert: ViewModifier {

    @NavigationState(\.importedRecord)
    private var importedRecord

    @Environment(\.deleteRun)
    private var deleteRun

    func body(content: Content) -> some View {
        content
            .alert(
                "Save to Library?",
                isPresented: Binding(
                    get: { importedRecord != nil },
                    set: { if !$0 { importedRecord = nil } }
                )
            ) {
                Button("Save") {
                    importedRecord = nil
                }
                Button("Remove", role: .destructive) {
                    if let record = importedRecord { deleteRun(record.entry) }
                    importedRecord = nil
                }
            } message: {
                if let record = importedRecord {
                    Text("Keep \(record.name) in your library?")
                }
            }
    }
}

extension View {
    func importDialogue() -> some View {
        modifier(ImportDialogueAlert())
    }
}
