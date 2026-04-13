import SwiftUI
import Metal
import CoreGraphics


public struct GradientsView: View {

    let state: VisualiserState

    public init(state: VisualiserState) {
        self.state = state
    }

    public var body: some View {
        let animTime    = state.time
        let coordinates = state.coordinates
        let direction   = state.direction
        let elevation   = state.elevation
        let heartRate   = state.heartRate
        let speed       = state.speed

        Rectangle()
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.bundle(.module).runGradientShader(
                        .float(animTime),
                        .float2(proxy.size),
                        .float2(coordinates),
                        .float2(direction),
                        .float(elevation),
                        .float(heartRate),
                        .float(speed)
                    )
                )
            }
    }
}

#Preview {
    GradientsView(state: .zero)
}
