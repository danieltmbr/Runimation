import SwiftUI

struct RunMenuActions: View {
    
    let run: RunEntry
    
    var body: some View {
        FavouriteRunToggle(isFavourite: .constant(false))
        RunStatsButton(run: run)
        ExportRunButton(run: run)
        Divider()
        DeleteRunButton(run: run)
    }
}

#Preview {
    RunMenuActions(run: RunRecord.sedentary.entry)
}
