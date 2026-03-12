import SwiftUI
import Metal
import CoreGraphics

public struct RunPathView: View {

    let state: AnimationState

    @State
    private var scale: CGFloat = 2

    @State
    private var baseScale: CGFloat = 2

    @State
    private var offset: CGVector = .zero

    @State
    private var baseOffset: CGVector = .zero

    public init(state: AnimationState) {
        self.state = state
    }

    public var body: some View {
        
        let animTime    = state.time
        let scale       = self.scale
        let offset      = self.offset
        
        let coordinates = state.coordinates
        let direction   = state.direction
        let elevation   = state.elevation
        let heartRate   = state.heartRate
        let path        = state.path
        let pathData    = path.withUnsafeBytes { Data($0) }
        let speed       = state.speed

        Rectangle()
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.bundle(.module).runPathShader(
                        .float(animTime),
                        .float2(proxy.size),
                        .float(scale),
                        .float2(offset),
                        .float2(coordinates),
                        .float2(direction),
                        .float(elevation),
                        .float(heartRate),
                        .data(pathData),
                        .float(speed)
                    )
                )
            }
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
    }


    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let px = CGFloat(value.startLocation.x)
                let py = CGFloat(value.startLocation.y)
                let newScale = clamp(baseScale / value.magnification, min: 0.1, max: 5)
                offset = CGVector(
                    dx: baseOffset.dx + px * (baseScale - newScale),
                    dy: baseOffset.dy + py * (baseScale - newScale)
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
                offset.dx = baseOffset.dx - value.translation.width * Double(scale)
                offset.dy = baseOffset.dy - value.translation.height * Double(scale)
            }
            .onEnded { _ in
                baseOffset = offset
            }
    }

    private func clamp(_ value: CGFloat, min lo: CGFloat, max hi: CGFloat) -> CGFloat {
        Swift.min(hi, Swift.max(lo, value))
    }
}

#Preview {
    RunPathView(state: .zero)
}

extension Shader.Argument {
    static func float2(_ simd: SIMD2<Float>) -> Shader.Argument {
        .float2(simd.x, simd.y)
    }
}
