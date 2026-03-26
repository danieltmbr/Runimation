import SwiftUI
import RunUI

struct RunEntryRow<Actions: View>: View {
    
    @ViewBuilder
    let actions: (LibraryEntry) -> Actions
    
    let entry: LibraryEntry
    
    init(
        entry: LibraryEntry,
        @ViewBuilder actions: @escaping (LibraryEntry) -> Actions
    ) {
        self.actions = actions
        self.entry = entry
    }
    
    var body: some View {
        HStack {
            RunInfoView(
                name: entry.name,
                date: entry.date,
                distance: entry.distance,
                duration: entry.duration
            )
            .runInfoStyle(.compact)
            
            Spacer()
            
            Menu {
                actions(entry)
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
}
