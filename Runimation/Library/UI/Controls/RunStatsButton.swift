import SwiftUI

struct RunStatsButton: View {
    
    @NavigationState(\.statsPath)
    private var stats
    
    let run: RunEntry
    
    var body: some View {
#if os(macOS)
        Button {
            stats.append(run)
        } label: {
            Label("Stats", systemImage: "chart.bar")
        }
#else
        NavigationLink(value: run) {
            Label("Stats", systemImage: "chart.bar")
        }
#endif
    }
}

#Preview {
    RunStatsButton(run: RunRecord.sedentary.entry)
}
