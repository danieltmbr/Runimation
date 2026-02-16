import SwiftUI

struct NoiseView: View {
    
    @State
    private var interpolationMode: InterpolationMode = .linear
    
    @State
    private var startTime = Date()
    
    @State
    private var scale: Double = 1

    
    enum InterpolationMode: String, CaseIterable, Sendable {
        case linear = "Linear (Fractional)"
        case smooth = "Smooth (Quintic)"
        
        var modeValue: Float {
            switch self {
            case .linear: return 0.0
            case .smooth: return 1.0
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // The noise visualization
            TimelineView(.animation) { timeline in
                let elapsed: TimeInterval = timeline.date.timeIntervalSince(startTime)
                Rectangle()
                    .visualEffect { content, proxy in
                        content
                            .colorEffect(
                                ShaderLibrary.noiseShader(
                                    .float(elapsed),
                                    .float(scale),
                                    .float(interpolationMode.modeValue)
                                )
                            )
                    }
            }
            
            // Control panel
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interpolation Mode")
                        .font(.headline)
                    
                    Picker("Mode", selection: $interpolationMode) {
                        ForEach(InterpolationMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scale: \(scale, specifier: "%.4f")")
                        .font(.headline)
                    Text("Zoom level (smaller = more zoomed out)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Slider(value: $scale, in: 1...1000)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("What you're seeing:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if interpolationMode == .linear {
                        Text("• Using raw fractional values for interpolation\n• Notice the grid artifacts and discontinuities\n• Colors change abruptly at cell boundaries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("• Using quintic polynomial (smootherstep)\n• Smooth transitions between cells\n• No visible grid artifacts\n• This is 'proper' noise!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.background)
        }
        .navigationTitle("2D Noise Interpolation")
    }
}

#Preview {
    NavigationStack {
        NoiseView()
    }
}
