import SwiftUI

struct ColoringView: View {
    @State private var technique: ColoringTechnique = .derivative
    @State private var h: Double = 0.5
    @State private var octaves: Double = 6.0
    @State private var scale: Double = 0.01
    @State private var time: Double = 0.0
    
    enum ColoringTechnique: String, CaseIterable {
        case derivative = "Derivative-Based"
        case multiLayer = "Multi-Layer"
        case warp = "Warp Amount"
        case animated = "Animated Warp"
        
        var description: String {
            switch self {
            case .derivative:
                return "Colors based on how fast the noise changes"
            case .multiLayer:
                return "Multiple noise layers with different color palettes"
            case .warp:
                return "Colors based on displacement amount"
            case .animated:
                return "Animated warping effect (for Strava viz)"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Visualization
            Rectangle()
                .visualEffect { content, geometryProxy in
                    content.colorEffect(shaderForTechnique)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Controls
            VStack(alignment: .leading, spacing: 20) {
                // Technique selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technique")
                        .font(.headline)
                    
                    Picker("Technique", selection: $technique) {
                        ForEach(ColoringTechnique.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(technique.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Parameters
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scale: \(scale, specifier: "%.4f")")
                            .font(.headline)
                        Slider(value: $scale, in: 0.001...0.05)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("H Parameter: \(h, specifier: "%.2f")")
                            .font(.headline)
                        Slider(value: $h, in: 0...1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Octaves: \(Int(octaves))")
                            .font(.headline)
                        Slider(value: $octaves, in: 1...12, step: 1)
                    }
                }
                
                // Recommended settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Settings")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button("Smooth Ice") {
                            scale = 0.005
                            octaves = 4
                            h = 0.7
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Detailed") {
                            scale = 0.015
                            octaves = 8
                            h = 0.5
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Turbulent") {
                            scale = 0.025
                            octaves = 10
                            h = 0.3
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .onAppear {
            // Start animation timer
            Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
                time += 0.016
            }
        }
    }
    
    private var shaderForTechnique: Shader {
        switch technique {
        case .derivative:
            return Shader(
                function: ShaderFunction(library: .default, name: "derivativeColorShader"),
                arguments: [
                    .float(time),
                    .float(octaves),
                    .float(h),
                    .float(scale)
                ]
            )
        case .multiLayer:
            return Shader(
                function: ShaderFunction(library: .default, name: "multiLayerColorShader"),
                arguments: [
                    .float(time),
                    .float(octaves),
                    .float(h),
                    .float(scale)
                ]
            )
        case .warp:
            return Shader(
                function: ShaderFunction(library: .default, name: "warpColorShader"),
                arguments: [
                    .float(time),
                    .float(octaves),
                    .float(h),
                    .float(scale)
                ]
            )
        case .animated:
            return Shader(
                function: ShaderFunction(library: .default, name: "animatedWarpShader"),
                arguments: [
                    .float(time),
                    .float(octaves),
                    .float(h),
                    .float(scale)
                ]
            )
        }
    }
}

#Preview {
    ColoringView()
}
