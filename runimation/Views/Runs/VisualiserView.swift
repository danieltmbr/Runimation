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
    private var selectedPanel: InspectorFocus = .visualisation

    @State
    private var visualisation: any Animations.Visualisation = Warp()

    var body: some View {
        PlayerDrivenView(visualisation: $visualisation)
            .ignoresSafeArea()
            .backgroundExtensionEffect()
#if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
#endif
        .inspector(isPresented: $showInspector) {
#if os(macOS)
            PlayerInspectorView(selectedPanel: $selectedPanel, visualisation: $visualisation)
                .inspectorColumnWidth(min: 200, ideal: 270, max: 400)
                .player(player)
#else
            PlayerSheetView(selectedPanel: $selectedPanel, visualisation: $visualisation)
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

/// Bridges `RunPlayer` state into `VisualisationCanvas` at 60 fps.
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

    var visualisation: Binding<any Animations.Visualisation>

    var body: some View {
        VisualisationCanvas(
            state: AnimationState(
                coordinates: SIMD2(Float(segment.coordinate.x), Float(segment.coordinate.y)),
                direction: SIMD2(Float(segment.direction.x), Float(segment.direction.y)),
                elevation: Float(segment.elevation),
                heartRate: Float(segment.heartRate),
                path: run.coordinates.map { SIMD2(Float($0.x), Float($0.y)) },
                speed: Float(segment.speed),
                time: Float(progress * duration(for: run.duration))
            ),
            visualisation: visualisation
        )
    }
}
