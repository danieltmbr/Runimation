import RunUI
import RunKit
import SwiftUI

struct RunMenuActions: View {
    
    let run: RunItem
    
    var body: some View {
        FavouriteRunToggle(isFavourite: .constant(false))
        RunStatsButton(run: run)
        ExportRunButton(run: run)
        Divider()
        DeleteRunButton(run: run)
    }
}

#Preview {
    RunMenuActions(run: RunRecord.sedentary.item)
}
