import CoreUI
import SwiftUI

/// View modifier that presents `ExportSheet` when `ExportNavigation.exportingRun` is set.
///
/// Apply once at the window root:
/// ```swift
/// RuniView()
///     .exportDialogue(viewportSize: viewportSize)
/// ```
///
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

public extension View {
    func exportDialogue(viewportSize: CGSize) -> some View {
        modifier(ExportDialogueSheet(viewportSize: viewportSize))
    }
}
