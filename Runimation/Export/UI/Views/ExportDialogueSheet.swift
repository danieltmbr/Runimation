import CoreUI
import SwiftUI

private struct ExportDialogueSheet: ViewModifier {

    @Navigation(\.export.exportingRun)
    private var exportingRun

    let viewportSize: CGSize

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: Binding(
                    get: { exportingRun != nil },
                    set: { if !$0 { exportingRun = nil } }
                )
            ) {
                if let run = exportingRun {
                    ExportSheet(run: run, viewportSize: viewportSize)
                }
            }
    }
}

extension View {
    func exportDialogue(viewportSize: CGSize) -> some View {
        modifier(ExportDialogueSheet(viewportSize: viewportSize))
    }
}
