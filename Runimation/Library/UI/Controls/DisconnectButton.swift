import SwiftUI

/// A reusable button that disconnects from the data source.
///
/// Requires `.library(_:player:)` in the view hierarchy.
///
struct DisconnectButton: View {

    @Environment(\.disconnectLibrary)
    private var disconnect

    var body: some View {
        Button("Disconnect", systemImage: "rectangle.portrait.and.arrow.forward", role: .destructive) {
            disconnect()
        }
    }
}
