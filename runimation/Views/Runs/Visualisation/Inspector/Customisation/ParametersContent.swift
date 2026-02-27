import SwiftUI

// MARK: - Parameters Content

struct ParametersContent: View {

    @Binding
    var baseH: Double
    
    @Binding
    var octaves: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("H: \(baseH, specifier: "%.2f")")
                    .font(.caption)
                Slider(value: $baseH, in: 0...1)
            }
            HStack {
                Text("Octaves: \(Int(octaves))")
                    .font(.caption)
                Slider(value: $octaves, in: 1...12, step: 1)
            }
        }
        .padding()
    }
}
