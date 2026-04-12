import CoreUI
import RunKit
import SwiftUI

/// A button (macOS) or `NavigationLink` (iOS) that opens run statistics.
///
/// On macOS, appends the run to `\.library.statsPath` so the main
/// `NavigationStack` handles the destination. On iOS, pushes directly
/// via a `NavigationLink`.
///
public struct RunStatsButton: View {

    @Navigation(\.library.statsPath)
    private var stats

    let run: RunItem

    public init(run: RunItem) {
        self.run = run
    }

    public var body: some View {
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
    RunStatsButton(
        run: RunItem(
            id: .init(),
            name: "Morning run",
            date: .now,
            distance: 5000,
            duration: 30*60*60,
            source: .document
        )
    )
}
