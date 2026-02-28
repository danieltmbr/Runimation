import SwiftUI

// MARK: - Animation Preferences Content

struct AnimationPreferencesContent: View {

    @Binding
    var baseH: Double
    
    @Binding
    var octaves: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Smoothing")
                    .font(.caption)
                Slider(value: $baseH, in: 0...1)
            }
            VStack(alignment: .leading) {
                Text("Details")
                    .font(.caption)
                Slider(value: $octaves, in: 1...12, step: 1)
            }
        }
        .padding()
    }
}
