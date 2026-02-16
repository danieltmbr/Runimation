import SwiftUI

struct FbmView: View {
    @State
    private var h: Double = 0.5
    
    @State
    private var octaves: Double = 4.0
    
    @State
    private var scale: Double = 0.01
    
    @State
    private var time: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            // The FBM visualization
            Rectangle()
                .visualEffect { content, geometryProxy in
                    content
                        .colorEffect(
                            ShaderLibrary.fbmShader(
                                .float(time),
                                .float(octaves),
                                .float(h),
                                .float(scale)
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
            .background(.ultraThinMaterial)
        }
        .onAppear {
            // Optional: animate time for dynamic effects
            Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
                time += 0.016
            }
        }
    }
}

#Preview {
    FbmView()
}
