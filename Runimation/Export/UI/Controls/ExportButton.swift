import SwiftUI

/// Toolbar button that triggers the export sheet for the currently playing run.
///
/// Sets `exportingRun` in `NavigationModel` — the sheet is presented by the
/// window root view, which owns both the record and the viewport size.
///
/// Disabled when no run is loaded. Requires `@NowPlaying` and `@NavigationState`
/// in the environment.
///
struct ExportButton: View {

    @NowPlaying
    private var nowPlaying

    @NavigationState(\.exportingRun)
    private var exportingRun

    var body: some View {
        Button {
            exportingRun = nowPlaying.record.item
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .disabled(nowPlaying.isSedentary)
    }
}
