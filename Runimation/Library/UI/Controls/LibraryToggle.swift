import SwiftUI

struct LibraryToggle: View {
    
    @NavigationState(\.columnVisibility)
    private var columnVisibility

    @NavigationState(\.showLibrary)
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
