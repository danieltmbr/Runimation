import SwiftUI

struct RunPlayerView: View {

    @PlayerState(\.segments.animation)
    private var animationSegment
    
    @PlayerState(\.progress)
    private var progress
    
    @PlayerState(\.runs)
    private var runs
    
    @PlayerState(\.duration)
    private var duration

    @State
    private var scale: Float = 0.005
    
    @State
    private var baseScale: Float = 0.005
    
    @State
    private var offset: SIMD2<Float> = .zero
    
    @State
    private var baseOffset: SIMD2<Float> = .zero

    
    @State
    private var baseH: Double = 0.5
    
    @State
    private var octaves: Double = 6.0
    
    @State
    private var showControls = false
    
    @State
    private var showDiagnostics = false

    
    var body: some View {
        VStack(spacing: 0) {
            // RunPlayer.progress changes every ~16ms on the main actor via its
            // internal Task timer. @Observable tracks the access to `progress`
            // (and `runs`) made here in body, so SwiftUI automatically re-renders
            // this view on each tick — no TimelineView needed.
            let segment  = animationSegment
            let animTime = Float(progress * animationDuration)
            let speed    = Float(segment?.speed ?? 0)
            let hr       = Float(segment?.heartRate ?? 0.5)
            let dx       = Float(segment?.direction.x ?? 0)
            let dy       = Float(segment?.direction.y ?? 0)
            let h        = shaderH(elevation: segment?.elevation ?? 0.5)

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
            .overlay(alignment: .topLeading) {
                RunPlayerStatsOverlay()
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
                    RunPlayerDiagnosticsOverlay()
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

            RunPlayerControlsView()
        }
    }

    // MARK: - Private

    /// Scale progress into a time range comparable to animationTime in PlaybackEngine.
    /// Using the playback duration so a 15s run and a real-time run both animate at the
    /// same visual speed.
    private var animationDuration: Double {
        guard let run = runs?.run(for: .metrics) else { return 15 }
        return duration(for: run.duration)
    }

    private func shaderH(elevation: Double) -> Float {
        let offset = (1.0 - elevation - 0.5) * 0.3
        return Float(max(0, min(1, baseH + offset)))
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let px = Float(value.startLocation.x)
                let py = Float(value.startLocation.y)
                let newScale = clamp(baseScale / Float(value.magnification), min: 0.001, max: 0.05)
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

// MARK: - Stats Overlay

private struct RunPlayerStatsOverlay: View {

    @PlayerState(\.segments.metrics) private var metricsSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let segment = metricsSegment {
                statRow("Pace",       value: pace(speed: segment.speed),                    unit: "min/km")
                statRow("Elevation",  value: String(format: "%.0f", segment.elevation),     unit: "m")
                statRow("Heart Rate", value: String(format: "%.0f", segment.heartRate),     unit: "bpm")
            }
        }
        .font(.caption)
        .monospacedDigit()
        .padding(8)
//        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
    }

    private func statRow(_ label: String, value: String, unit: String) -> some View {
        HStack(spacing: 4) {
            Text(label).foregroundStyle(.secondary)
            Text(value).fontWeight(.medium).frame(minWidth: 36, alignment: .trailing)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    private func pace(speed: Double) -> String {
        guard speed > 0.3 else { return "--:--" }
        let secsPerKm = 1000.0 / speed
        return String(format: "%d:%02d", Int(secsPerKm) / 60, Int(secsPerKm) % 60)
    }
}
