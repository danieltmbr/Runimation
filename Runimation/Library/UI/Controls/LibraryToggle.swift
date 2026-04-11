import CoreUI
import SwiftUI

struct LibraryToggle: View {

    @Navigation(\.library.columnVisibility)
    private var columnVisibility

    @Navigation(\.library.showLibrary)
    private var showLibrary
    
    var body: some View {
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
