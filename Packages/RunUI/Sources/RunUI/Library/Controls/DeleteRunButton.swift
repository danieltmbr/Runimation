import RunKit
import SwiftUI

/// A destructive button that removes a run entry from the library.
///
/// Reads `DeleteRunAction` from the environment, which is injected
/// by `.library(_:)`. Suitable for use in swipe actions and context menus.
///
/// Requires `.library(_:)` in the view hierarchy.
///
public struct DeleteRunButton: View {

    @Environment(\.deleteRun)
    private var deleteRun

    let run: RunEntry

    public init(run: RunEntry) {
        self.run = run
    }

    public var body: some View {
        Button(role: .destructive) {
            deleteRun(run)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
