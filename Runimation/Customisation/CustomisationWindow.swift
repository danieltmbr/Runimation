#if os(macOS)
import RunKit
import SwiftUI
import RunUI

/// macOS floating window that tracks whichever player window is focused.
///
/// Reads the focused player window's `NavigationModel` via `@FocusedValue` and
/// injects that window's `RunPlayer` and `NowPlayingModel` into `CustomisationPanel`.
///
/// The caching pattern (`cachedNav`) keeps the panel functional when the user
/// clicks inside the customisation window itself — that click shifts focus away
/// from the player window, making `@FocusedValue` nil. The cached value fills
/// the gap until focus returns to a player window.
///
/// Requires `.library(_:)` applied from the scene so library actions are available.
///
struct CustomisationWindow: View {

    @FocusedValue(\.navigationModel)
    private var focusedNav

    @State
    private var cachedNav: NavigationModel?

    private var activeNav: NavigationModel? { focusedNav ?? cachedNav }

    var body: some View {
        Group {
            if let nav = activeNav {
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
        .onChange(of: focusedNav) { _, new in
            if let new { cachedNav = new }
        }
    }
}
#endif
