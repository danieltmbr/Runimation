import SwiftUI

struct VisualiserView: View {

    @PlayerState(\.segment.animation)
    private var animationSegment

    @PlayerState(\.progress)
    private var progress

    @PlayerState(\.runs)
    private var runs

    @PlayerState(\.duration)
    private var duration

    @Environment(RunPlayer.self)
    private var player

    @Binding
    var showInspector: Bool

    @State
    private var selectedPanel: InspectorFocus = .animation

    @State
    private var baseH: Double = 0.8

    @State
    private var octaves: Double = 5.0

    @State
    private var scale: Float = 0.007

    @State
    private var baseScale: Float = 0.007

    @State
    private var offset: SIMD2<Float> = .zero

    @State
    private var baseOffset: SIMD2<Float> = .zero

    var body: some View {
        // RunPlayer.progress changes every ~16ms on the main actor via its
        // internal Task timer. @Observable tracks the access to `progress`
        // (and `runs`) made here in body, so SwiftUI automatically re-renders
        // this view on each tick — no TimelineView needed.
        let segment  = animationSegment
        let animTime = Float(progress * animationDuration)
        let speed    = Float(segment.speed)
        let scale    = self.scale
        let hr       = Float(segment.heartRate)
        let dx       = Float(segment.direction.x)
        let dy       = Float(segment.direction.y)
        let h        = shaderH(elevation: segment.elevation)
        let offset   = self.offset
        let octaves  = Float(self.octaves)

        Rectangle()
            .visualEffect { content, _ in
                content.colorEffect(
                    ShaderLibrary.runShader(
                        .float(animTime),
                        .float(octaves),
                        .float(h),
                        .float(scale),
                        .float(speed),
                        .float(hr),
                        .float(dx),
                        .float(dy),
                        .float(offset.x),
                        .float(offset.y)
                    )
                )
            }
            .ignoresSafeArea()
            .backgroundExtensionEffect()
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
#if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
#endif
            .inspector(isPresented: $showInspector) {
#if os(macOS)
                PlayerInspectorView(selectedPanel: $selectedPanel, baseH: $baseH, octaves: $octaves)
                    .inspectorColumnWidth(min: 200, ideal: 270, max: 400)
                    .player(player)
#else
                PlayerSheetView(selectedPanel: $selectedPanel, baseH: $baseH, octaves: $octaves)
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

    // MARK: - Private

    /// Scale progress into a time range comparable to animationTime in PlaybackEngine.
    /// Using the playback duration so a 15s run and a real-time run both animate at the
    /// same visual speed.
    private var animationDuration: Double {
        guard let run = runs?.run(for: .metrics) else { return 0 }
        return duration(for: run.duration)
    }

    private func shaderH(elevation: Double) -> Float {
        let elevationOffset = (1.0 - elevation - 0.5) * 0.3
        return Float(max(0, min(1, baseH + elevationOffset)))
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let px = Float(value.startLocation.x)
                let py = Float(value.startLocation.y)
                let newScale = clamp(baseScale / Float(value.magnification), min: 0.0005, max: 0.025)
                // Keep the noise coordinate under the pinch fixed:
                // noiseX = px * baseScale + baseOffset.x = px * newScale + newOffset.x
                offset = SIMD2(
                    baseOffset.x + px * (baseScale - newScale),
                    baseOffset.y + py * (baseScale - newScale)
                )
                scale = newScale
            }
            .onEnded { _ in
                baseScale = scale
                baseOffset = offset
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset.x = baseOffset.x - Float(value.translation.width) * scale
                offset.y = baseOffset.y - Float(value.translation.height) * scale
            }
            .onEnded { _ in
                baseOffset = offset
            }
    }

    private func clamp(_ value: Float, min lo: Float, max hi: Float) -> Float {
        Swift.min(hi, Swift.max(lo, value))
    }
}
