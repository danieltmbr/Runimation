import RunKit
import SwiftUI

private struct DisconnectDialogue: ViewModifier {
    
    @Environment(\.disconnect)
    private var disconnect
    
    @Binding
    private var isPresented: Bool
    
    private let tracker: TrackerID
    
    init(
        isPresented: Binding<Bool>,
        tracker: TrackerID
    ) {
        self._isPresented = isPresented
        self.tracker = tracker
    }
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Disconnect \(tracker.name)",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Keep Runs") { disconnect(tracker, keepRuns: true) }
                Button("Remove Runs", role: .destructive) { disconnect(tracker, keepRuns: false) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Would you like to keep your \(tracker.name) runs in the library?")
            }
    }
}

extension View {
    func disconnectDialogue(
        tracker: TrackerID,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            DisconnectDialogue(
                isPresented: isPresented,
                tracker: tracker
            )
        )
    }
}
