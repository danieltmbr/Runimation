import SwiftUI

/// A reusable button that disconnects from the data source.
///
/// Tapping shows a confirmation alert asking whether to keep or remove
/// the Strava runs from the library before signing out.
///
/// Requires `.library(_:)` in the view hierarchy.
///
struct DisconnectButton: View {

    @Environment(\.disconnectLibrary)
    private var disconnect

    @State
    private var isConfirming = false

    var body: some View {
        Button("Disconnect", systemImage: "rectangle.portrait.and.arrow.forward", role: .destructive) {
            isConfirming = true
        }
        .confirmationDialog(
            "Disconnect from Strava",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Keep Runs") { disconnect(keepRuns: true) }
            Button("Remove Runs", role: .destructive) { disconnect(keepRuns: false) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to keep your Strava runs in the library or remove them?")
        }
    }
}
