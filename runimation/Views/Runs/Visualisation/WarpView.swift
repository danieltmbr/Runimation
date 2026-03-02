import SwiftUI
import RunKit
import RunUI

struct WarpView: View {
    
    @PlayerState(\.segment.animation)
    private var animationSegment
    
    @PlayerState(\.progress)
    private var progress
    
    @PlayerState(\.runs.animation)
    private var run
    
    @PlayerState(\.duration)
    private var duration
    
    @State
    private var scale: Float = 0.007
    
    @State
    private var baseScale: Float = 0.007
    
    @State
    private var offset: SIMD2<Float> = .zero
    
    @State
    private var baseOffset: SIMD2<Float> = .zero
    
    var smoothness: Binding<Double>
    
    var details: Binding<Double>
    
    var body: some View {
        
        // RunPlayer.progress changes every ~16ms on the main actor via its
        // internal Task timer. @Observable tracks the access to `progress`
        // (and `runs`) made here in body, so SwiftUI automatically re-renders
        // this view on each tick — no TimelineView needed.
        let segment  = animationSegment
        let animTime = Float(progress * duration(for: run.duration))
        let speed    = Float(segment.speed)
        let scale    = self.scale
        let hr       = Float(segment.heartRate)
        let dx       = Float(segment.direction.x)
        let dy       = Float(segment.direction.y)
        let h        = shaderH(elevation: segment.elevation)
        let offset   = self.offset
        let octaves  = Float(self.details.wrappedValue)
        
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
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
    }
    
    // MARK: - Private
        
    private func shaderH(elevation: Double) -> Float {
        let elevationOffset = (1.0 - elevation - 0.5) * 0.3
        return Float(max(0, min(1, smoothness.wrappedValue + elevationOffset)))
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
    WarpView(smoothness: .constant(1), details: .constant(5))
}
