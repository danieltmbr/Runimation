import SwiftUI

struct RunView: View {
    let engine: PlaybackEngine

    // Zoom & pan in noise-space
    // UV formula: uv = position * scale + offset
    // "offset" is the noise-space coordinate of the screen's top-left corner
    @State private var scale: Float = 0.005
    @State private var baseScale: Float = 0.005
    @State private var offset: SIMD2<Float> = .zero
    @State private var baseOffset: SIMD2<Float> = .zero
    @State private var viewSize: CGSize = CGSize(width: 400, height: 800)

    // User-adjustable shader params
    @State private var baseH: Double = 0.5
    @State private var octaves: Double = 6.0
    @State private var showControls = false
    @State private var showDiagnostics = false

    private var shaderH: Float {
        let elevationOffset = (1.0 - Double(engine.currentElevation) - 0.5) * 0.3
        return Float(max(0, min(1, baseH + elevationOffset)))
    }

    var body: some View {
        VStack(spacing: 0) {
            // TimelineView acts as a per-frame heartbeat so colorEffect re-evaluates
            // with fresh engine values each frame. engine.update() is driven by ContentView.
            TimelineView(.animation(paused: !engine.isPlaying)) { _ in
                // Read engine properties here, inside the @ViewBuilder body.
                // @Observable tracks accesses made during body/view-builder execution,
                // but NOT inside .visualEffect closures (which run at Metal render time).
                // Capturing locals forces RunView to re-render each frame when
                // engine.update() mutates these values.
                let animTime = engine.animationTime
                let speed    = engine.currentSpeed
                let hr       = engine.currentHeartRate
                let dx       = engine.currentDirX
                let dy       = engine.currentDirY
                let h        = shaderH   // reads engine.currentElevation
                GeometryReader { geo in
                    Rectangle()
                        .visualEffect { content, _ in
                            content.colorEffect(
                                ShaderLibrary.runShader(
                                    .float(animTime),
                                    .float(Float(octaves)),
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
                        .onAppear {
                            viewSize = geo.size
                        }
                        .onChange(of: geo.size) { _, newSize in
                            viewSize = newSize
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
            .overlay(alignment: .topLeading) {
                RunStatsOverlay(engine: engine)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Button(action: { showDiagnostics.toggle() }) {
                        Image(systemName: "waveform.path.ecg")
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    Button(action: { showControls.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(12)
            }
            .overlay(alignment: .bottom) {
                if showDiagnostics {
                    RunDiagnosticsOverlay(engine: engine)
                }
            }

            if showControls {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("H: \(baseH, specifier: "%.2f")")
                            .font(.caption)
                        Slider(value: $baseH, in: 0...1)
                    }
                    HStack {
                        Text("Octaves: \(Int(octaves))")
                            .font(.caption)
                        Slider(value: $octaves, in: 1...12, step: 1)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }

            PlaybackControlsView(engine: engine)
        }
    }

    // MARK: - Gestures

    /// Pinch-to-zoom anchored at view center.
    /// Pinch out (magnification > 1) = zoom in = smaller scale.
    /// Adjusts offset so the center pixel keeps its noise coordinate.
    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = clamp(baseScale / Float(value.magnification), min: 0.001, max: 0.05)
                let oldScale = scale

                // Keep noise coordinate at view center fixed:
                // noiseCenterX = (viewWidth/2) * oldScale + oldOffsetX
                // noiseCenterX = (viewWidth/2) * newScale + newOffsetX
                // => newOffsetX = oldOffsetX + (viewWidth/2) * (oldScale - newScale)
                let cx = Float(viewSize.width) / 2.0
                let cy = Float(viewSize.height) / 2.0
                offset.x += cx * (oldScale - newScale)
                offset.y += cy * (oldScale - newScale)

                scale = newScale
            }
            .onEnded { _ in
                baseScale = scale
                baseOffset = offset
            }
    }

    /// Drag to pan — dragging right moves the noise field right (offset decreases).
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
