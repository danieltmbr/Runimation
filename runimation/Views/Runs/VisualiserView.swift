import SwiftUI
import RunKit
import RunUI
import Animations

struct VisualiserView: View {

    @Environment(RunPlayer.self)
    private var player

    @Binding
    var showInspector: Bool

    @State
    private var selectedPanel: InspectorFocus = .animation

    @State
    private var warp = Warp()

    var body: some View {
        PlayerDrivenView(configuration: $warp)
            .ignoresSafeArea()
            .backgroundExtensionEffect()
#if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
#endif
        .inspector(isPresented: $showInspector) {
#if os(macOS)
            PlayerInspectorView(selectedPanel: $selectedPanel, warp: $warp)
                .inspectorColumnWidth(min: 200, ideal: 270, max: 400)
                .player(player)
#else
            PlayerSheetView(selectedPanel: $selectedPanel, warp: $warp)
                .player(player)
#endif
        }
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .principal) {
                PlaybackControls()
                    .playbackControlsStyle(.toolbar)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showInspector.toggle() } label: {
                    Image(systemName: "sidebar.right")
                }
            }
#endif
        }
    }
}

// MARK: - Player-Driven View

/// Bridges `RunPlayer` state into `WarpView` at 60 fps.
///
/// Kept as a separate named struct so only this view's body re-renders at the
/// animation frame rate — `VisualiserView` and the inspector remain unaffected.
///
private struct PlayerDrivenView: View {

    @PlayerState(\.segment.animation)
    private var segment

    @PlayerState(\.progress.animation)
    private var progress

    @PlayerState(\.run.animation)
    private var run

    @PlayerState(\.duration)
    private var duration

    var configuration: Binding<Warp>

    var body: some View {
        WarpView(
            state: AnimationState(
                time: Float(progress * duration(for: run.duration)),
                speed: Float(segment.speed),
                heartRate: Float(segment.heartRate),
                elevation: Float(segment.elevation),
                direction: SIMD2(Float(segment.direction.x), Float(segment.direction.y))
            ),
            configuration: configuration
        )
    }
}
