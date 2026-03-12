import SwiftUI
import RunKit
import RunUI
import Animations

struct PathView: View {
    
    @Environment(RunPlayer.self)
    private var player
    
    var body: some View {
        PlayerDrivenView()
            .ignoresSafeArea()
            .backgroundExtensionEffect()
#if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
#endif
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .principal) {
                    PlaybackControls()
                        .playbackControlsStyle(.toolbar)
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
        
    var body: some View {
        RunPathView(
            state: AnimationState(
                coordinates: SIMD2(Float(segment.coordinate.x), Float(segment.coordinate.y)),
                direction: SIMD2(Float(segment.direction.x), Float(segment.direction.y)),
                elevation: Float(segment.elevation),
                heartRate: Float(segment.heartRate),
                path: run.coordinates.map { SIMD2(Float($0.x), Float($0.y)) },
                speed: Float(segment.speed),
                time: Float(progress * duration(for: run.duration))
            )
        )
    }
}
