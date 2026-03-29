import SwiftUI

/// Toolbar button that opens the `ExportSheet` for the currently playing run.
///
/// Disabled when no run is loaded (sedentary state). Requires `@NowPlaying` in the
/// environment via `.library(_:)`.
///
struct ExportButton: View {

    @NowPlaying
    private var nowPlaying

    let viewportSize: CGSize

    @State
    private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .disabled(nowPlaying.isSedentary)
        .sheet(isPresented: $isPresented) {
            ExportSheet(viewportSize: viewportSize)
        }
    }
}
