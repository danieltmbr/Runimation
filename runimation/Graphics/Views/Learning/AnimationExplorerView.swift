import SwiftUI

struct AnimationExplorerView: View {
    @State private var animationType: AnimationType = .flowing
    @State private var h: Double = 0.5
    @State private var octaves: Double = 6.0
    @State private var scale: Double = 0.01
    @State private var time: Double = 0.0
    @State private var isPlaying: Bool = true
    @State private var animationSpeed: Double = 1.0
    
    enum AnimationType: String, CaseIterable, Identifiable {
        case orbital = "Orbital"
        case breathing = "Breathing"
        case flowing = "Flowing"
        case rotating = "Rotating"
        case complex = "Complex"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .orbital:
                return "Circular camera motion around a center point"
            case .breathing:
                return "Pulsing H parameter and scale for organic feel"
            case .flowing:
                return "Non-linear drift with varying speeds"
            case .rotating:
                return "Slow rotation of the entire domain"
            case .complex:
                return "Combined rotation, drift, and breathing"
            }
        }
        
        var shaderName: String {
            switch self {
            case .orbital: return "orbitalAnimationShader"
            case .breathing: return "breathingAnimationShader"
            case .flowing: return "flowingAnimationShader"
            case .rotating: return "rotatingAnimationShader"
            case .complex: return "complexAnimationShader"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Visualization
            Rectangle()
                .visualEffect { content, geometryProxy in
                    content.colorEffect(currentShader)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Controls
            VStack(alignment: .leading, spacing: 20) {
                // Animation type selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animation Type")
                        .font(.headline)
                    
                    Picker("Animation", selection: $animationType) {
                        ForEach(AnimationType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(animationType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Playback controls
                HStack(spacing: 16) {
                    Button(action: { isPlaying.toggle() }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed: \(animationSpeed, specifier: "%.1f")x")
                            .font(.caption)
                        Slider(value: $animationSpeed, in: 0.1...3.0)
                    }
                    
                    Button("Reset") {
                        time = 0.0
                    }
                    .buttonStyle(.bordered)
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
                
                // Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button("Subtle") {
                            scale = 0.005
                            octaves = 4
                            h = 0.6
                            animationSpeed = 0.5
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Dynamic") {
                            scale = 0.015
                            octaves = 6
                            h = 0.5
                            animationSpeed = 1.0
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Intense") {
                            scale = 0.025
                            octaves = 8
                            h = 0.3
                            animationSpeed = 1.5
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            if isPlaying {
                time += 0.016 * animationSpeed
            }
        }
    }
    
    private var currentShader: Shader {
        Shader(
            function: ShaderFunction(library: .default, name: animationType.shaderName),
            arguments: [
                .float(time),
                .float(octaves),
                .float(h),
                .float(scale)
            ]
        )
    }
}

#Preview {
    AnimationExplorerView()
}
