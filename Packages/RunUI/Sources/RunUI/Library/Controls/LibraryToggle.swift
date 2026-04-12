import CoreUI
import SwiftUI

/// Toolbar button that toggles the Run Library sidebar (macOS) or sheet (iOS).
public struct LibraryToggle: View {

    @Navigation(\.library.columnVisibility)
    private var columnVisibility

    @Navigation(\.library.showLibrary)
    private var showLibrary

    public init() {}

    public var body: some View {
        Button {
            withAnimation {
#if os(macOS)
                columnVisibility = columnVisibility == .detailOnly ? .automatic : .detailOnly
#else
                showLibrary.toggle()
#endif
            }
        } label: {
            Label("Run Library", systemImage: "figure.run")
        }
    }
}

#Preview {
    LibraryToggle()
}
