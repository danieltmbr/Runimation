import RunKit
import SwiftUI

/// A control that connects or disconnects a specific activity tracker.
///
/// Displays the tracker's display name and reflects its current connection
/// status — showing a connect button when disconnected and a destructive
/// disconnect button (with a keepRuns confirmation dialog) when connected.
///
/// Pass the specific tracker instance to control. Reads `RunLibrary` from
/// the environment to orchestrate connect/disconnect (which handles both
/// the tracker auth flow and any library-level side effects like refreshing
/// activities or removing stored runs).
///
/// Requires `.library(_:)` in the view hierarchy.
///
public struct ConnectToggle: View {

    public let tracker: any ActivityTracker

    @Environment(RunLibrary.self)
    private var library

    @State
    private var isConfirming = false

    public init(tracker: any ActivityTracker) {
        self.tracker = tracker
    }

    public var body: some View {
        if tracker.isConnected {
            disconnectButton
        } else {
            connectButton
        }
    }

    // MARK: - Buttons

    private var connectButton: some View {
        Button("Connect to \(tracker.displayName)") {
            Task { try? await library.connect(tracker) }
        }
    }

    private var disconnectButton: some View {
        Button(
            "Disconnect from \(tracker.displayName)",
            systemImage: "rectangle.portrait.and.arrow.forward",
            role: .destructive
        ) {
            isConfirming = true
        }
        .confirmationDialog(
            "Disconnect from \(tracker.displayName)",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Keep Runs") { library.disconnect(tracker, keepRuns: true) }
            Button("Remove Runs", role: .destructive) { library.disconnect(tracker, keepRuns: false) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to keep your \(tracker.displayName) runs in the library or remove them?")
        }
    }
}
