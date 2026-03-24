import Visualiser
import SwiftUI

/// Interactive demo exploring Fractional Brownian Motion (fBM) parameters.
/// Adjust H (roughness), octave count, and scale to see how each affects
/// the layered noise composition used in production warp shaders.
struct FbmDemoView: View {

    @State
    private var startTime = Date()

    @State
    private var h: Double = 0.5

    @State
    private var octaves: Double = 4.0

    @State
    private var scale: Double = 0.01

    var body: some View {
        VStack(spacing: 20) {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                let h       = self.h
                let octaves = self.octaves
                let scale   = self.scale
                Rectangle()
                    .visualEffect { content, _ in
                        content
                            .colorEffect(
                                ShaderLibrary.bundle(.visualiser).fbmShader(
                                    .float(elapsed),
                                    .float(octaves),
                                    .float(h),
                                    .float(scale)
                                )
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Controls
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scale: \(scale, specifier: "%.4f")")
                        .font(.headline)
                    Text("Zoom level (smaller = more zoomed out)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $scale, in: 0.001...0.1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("H Parameter: \(h, specifier: "%.2f")")
                        .font(.headline)
                    Text("Controls roughness/smoothness")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $h, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Octaves: \(Int(octaves))")
                        .font(.headline)
                    Text("Number of detail layers")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $octaves, in: 1...24, step: 1)
                }
            }
            .padding()
        }
    }
}

#Preview {
    FbmDemoView()
}
