import VisualiserUI
import SwiftUI

/// Switch between plain gradient and animated blob modes; pinch-to-zoom and
/// pan to explore the colour field. Demonstrates the gradient and blob shaders.
///
struct GradientDemoView: View {

    enum Gradient: String, CaseIterable, Sendable  {
        case plain = "Plain"
        case blob = "Blob"
    }

    enum BlobMode: String, CaseIterable, Sendable {
        case smoothstep = "Smoothstep"
        case exp = "Exponential"

        fileprivate var value: Int {
            switch self {
            case .smoothstep: 0
            case .exp: 1
            }
        }
    }

    @State
    private var gradient: Gradient = .plain

    @State
    private var blobMode: BlobMode = .smoothstep

    @State
    private var saturate: Bool = false

    @State
    private var highlight: Bool = false

    @State
    private var noise: Bool = false

    @State
    private var startTime = Date()

    @State
    private var scale: Float = 1

    @State
    private var baseScale: Float = 1

    @State
    private var offset: SIMD2<Float> = .zero

    @State
    private var baseOffset: SIMD2<Float> = .zero

    init() {}

    var body: some View {
        VStack {
            TimelineView(.animation) { timeline in
                let elapsed: TimeInterval = timeline.date.timeIntervalSince(startTime)
                gradients(elapsedTime: elapsed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(magnifyGesture)
                    .simultaneousGesture(panGesture)
            }

            HStack {
                Picker("Gradient", selection: $gradient) {
                    ForEach(Gradient.allCases, id: \.self) { gradient in
                        Text(gradient.rawValue).tag(gradient)
                    }
                }

                if gradient == .blob {
                    Picker("Blob Mode", selection: $blobMode) {
                        ForEach(BlobMode.allCases, id: \.self) { blob in
                            Text(blob.rawValue).tag(blob)
                        }
                    }

                    Toggle(isOn: $saturate) {
                        Text("Blob Saturation")
                    }

                    Toggle(isOn: $highlight) {
                        Text("Highlight")
                    }

                    Toggle(isOn: $noise) {
                        Text("Noise")
                    }
                }
            }
        }
    }

    // MARK: - Colors

    @ViewBuilder
    private func gradients(elapsedTime elapsed: TimeInterval) -> some View {
        switch gradient {
        case .plain:
            plain(elapsedTime: elapsed)
        case .blob:
            blob(elapsedTime: elapsed)
        }
    }

    @ViewBuilder
    private func plain(elapsedTime elapsed: TimeInterval) -> some View {
        let scale    = self.scale
        let offset   = self.offset
        Rectangle()
            .visualEffect { content, geometryProxy in
                var o = offset;
                o.x /= Float(geometryProxy.size.width)/scale
                o.y /= Float(-geometryProxy.size.height)/scale
                return content
                    .colorEffect(
                        ShaderLibrary.bundle(.visualiserUI).gradientShader(
                            .float(elapsed),
                            .float2(geometryProxy.size),
                            .float(scale),
                            .float2(o.x, o.y)
                        )
                    )
            }
    }

    @ViewBuilder
    private func blob(elapsedTime elapsed: TimeInterval) -> some View {
        let scale     = self.scale
        let offset    = self.offset
        let blobMode  = self.blobMode.value
        let saturate  = self.saturate ? Float(1) : 0
        let highlight = self.highlight ? Float(1) : 0
        let noise     = self.noise ? Float(1) : 0
        Rectangle()
            .visualEffect { content, geometryProxy in
                var o = offset
                o.x /= Float(geometryProxy.size.width) / scale
                o.y /= Float(-geometryProxy.size.height) / scale
                return content
                    .colorEffect(
                        ShaderLibrary.bundle(.visualiserUI).blobShader(
                            .float(elapsed),
                            .float2(geometryProxy.size),
                            .float(scale),
                            .float2(o.x, o.y),
                            .float(Float(blobMode)),
                            .float(saturate),
                            .float(highlight),
                            .float(noise)
                        )
                    )
            }
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let px = Float(value.startLocation.x)
                let py = Float(value.startLocation.y)
                let newScale = clamp(Float(value.magnification)/baseScale, min: 0.1, max: 20)
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
                offset.x = baseOffset.x - Float(value.translation.width)
                offset.y = baseOffset.y - Float(value.translation.height)
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
    GradientDemoView()
}
