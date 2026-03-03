import SwiftUI

/// A full-screen Metal-rendered domain warp animation.
///
/// Driven by an `AnimationState` value (constructed from run metrics in the app layer)
/// and a `Warp` configuration binding for user-adjustable parameters.
/// Supports pinch-to-zoom and pan gestures for noise-space navigation.
///
public struct WarpView: View {

    let state: AnimationState

    var configuration: Binding<Warp>

    @State
    private var scale: Float = 0.007

    @State
    private var baseScale: Float = 0.007

    @State
    private var offset: SIMD2<Float> = .zero

    @State
    private var baseOffset: SIMD2<Float> = .zero

    @State
    private var paletteImage: Image = PaletteGradientRenderer.image(.default)

    public init(state: AnimationState, configuration: Binding<Warp>) {
        self.state = state
        self.configuration = configuration
    }

    public var body: some View {

        // `state` changes every ~16ms when driven by a 60fps PlayerState observer.
        // SwiftUI re-renders this view on each tick — no TimelineView needed.
        let animTime = state.time
        let speed    = state.speed
        let scale    = self.scale
        let hr       = state.heartRate
        let dx       = state.direction.x
        let dy       = state.direction.y
        let h        = shaderH(elevation: state.elevation)
        let offset   = self.offset
        let octaves  = Float(configuration.wrappedValue.details)

        Rectangle()
            .visualEffect { content, _ in
                content.colorEffect(
                    ShaderLibrary.bundle(.module).runShader(
                        .float(animTime),
                        .float(octaves),
                        .float(h),
                        .float(scale),
                        .float(speed),
                        .float(hr),
                        .float(dx),
                        .float(dy),
                        .float(offset.x),
                        .float(offset.y),
                        .image(paletteImage)
                    )
                )
            }
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
            .onChange(of: configuration.wrappedValue.palette) { _, newPalette in
                paletteImage = PaletteGradientRenderer.image(newPalette)
            }
    }

    // MARK: - Private

    private func shaderH(elevation: Float) -> Float {
        let elevationOffset = (1.0 - Double(elevation) - 0.5) * 0.3
        return Float(max(0, min(1, configuration.wrappedValue.smoothness + elevationOffset)))
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

#Preview {
    WarpView(state: .zero, configuration: .constant(Warp()))
}
