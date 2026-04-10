#if os(macOS)
import RunKit
import SwiftUI
import RunUI

/// macOS floating window that tracks whichever player window is currently key.
///
/// Reads the active `NavigationModel` from `WindowCoordinator`, which is updated
/// by `RuniWindow` whenever it becomes the key window. This bypasses `@FocusedValue`,
/// which cannot cross SwiftUI scene boundaries (the Customisation window lives in a
/// separate `Window` scene from the main `WindowGroup`).
///
struct CustomisationWindow: View {

    @Environment(WindowCoordinator.self)
    private var coordinator

    var body: some View {
        Group {
            if let nav = coordinator.activeNavigationModel {
                VStack {
                    CustomisationPanel()
                        .padding()
                    Spacer()
                }
                .player(nav.player)
                .environment(nav.nowPlaying)
            } else {
                ContentUnavailableView(
                    "No Window Selected",
                    systemImage: "macwindow",
                    description: Text("Focus a run window to customise it.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.thinMaterial)
        .containerBackground(.clear, for: .window)
    }
}
#endif
