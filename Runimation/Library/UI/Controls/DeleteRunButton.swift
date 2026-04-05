import SwiftUI

struct DeleteRunButton: View {
    
    @Environment(\.deleteRun)
    private var deleteRun
    
    let run: RunEntry
    
    var body: some View {
        Button(role: .destructive) {
            deleteRun(run)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

#Preview {
    DeleteRunButton(run: RunRecord.sedentary.entry)
}
