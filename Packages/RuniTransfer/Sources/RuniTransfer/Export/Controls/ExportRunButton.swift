import CoreUI
import RunKit
import SwiftUI

/// Menu button that triggers the export sheet for a specific run record.
///
/// Sets `exportingRun` in `NavigationModel` — the sheet is presented by the
/// window root view, which owns the viewport size needed for video export.
///
public struct ExportRunButton: View {

    @Navigation(\.export.exportingRun)
    private var exportingRun

    let run: RunItem

    public init(run: RunItem) {
        self.run = run
    }

    public var body: some View {
        Button {
            exportingRun = run
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}
