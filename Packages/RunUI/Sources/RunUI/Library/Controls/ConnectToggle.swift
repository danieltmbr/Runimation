import RunKit
import SwiftUI

/// A control that connects or disconnects a specific activity tracker.
///
/// Displays the tracker's name and reflects its connection status — showing
/// a connect button when disconnected and a destructive disconnect button
/// (with a keepRuns confirmation dialog) when connected.
///
/// The primary initialiser accepts an `isConnected` binding and a `TrackerID`
/// so the view has no dependency on the tracker object itself at render time.
/// Use the convenience initialiser when the tracker is directly available:
///
/// ```swift
/// ConnectToggle(tracker: stravaTracker)
/// ```
///
/// Requires `.library(_:)` in the view hierarchy (for `connect`/`disconnect` actions).
/// On iOS, requires `.environment(\.presentationAnchor, window)` for the OAuth web session.
///
public struct ConnectToggle: View {

    @Environment(\.connect)
    private var connect

    @Environment(\.presentationAnchor)
    private var anchor

    @Binding
    private var isConnected: Bool

    private let tracker: TrackerID

    @State
    private var isConfirming = false

    public init(isConnected: Binding<Bool>, tracker: TrackerID) {
        _isConnected = isConnected
        self.tracker = tracker
    }

    public init(tracker: any ActivityTracker) {
        self.init(
            isConnected: Binding(get: { tracker.isConnected }, set: { _ in }),
            tracker: tracker.trackerID
        )
    }

    public var body: some View {
        Group {
            if isConnected {
                Button(
                    "Disconnect \(tracker.name)",
                    systemImage: "rectangle.portrait.and.arrow.forward",
                    role: .destructive
                ) {
                    isConfirming = true
                }
            } else {
                Button("Connect \(tracker.name)") {
                    connect(tracker, from: anchor)
                }
            }
        }
        .disconnectDialogue(
            tracker: tracker,
            isPresented: $isConfirming
        )
    }
}
