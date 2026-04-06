import SwiftUI
import RunKit

/// Menu button that triggers the export sheet for a specific run record.
///
/// Sets `exportingRun` in `NavigationModel` — the sheet is presented by the
/// window root view, which owns the viewport size needed for video export.
///
/// Requires `@NavigationState` in the environment via `.environment(navigationModel)`.
///
struct ExportRunButton: View {

    @NavigationState(\.exportingRun)
    private var exportingRun

    let run: RunEntry

    var body: some View {
        Button {
            exportingRun = run
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}
