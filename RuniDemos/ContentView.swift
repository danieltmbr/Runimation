import SwiftUI
import VisualiserUI

/// Root view for the RuniDemos app. Presents all shader learning demos
/// in a sidebar-style TabView so each can be explored independently.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Gradients", systemImage: "paintpalette") {
                GradientDemoView()
            }
            Tab("Noise", systemImage: "waveform") {
                NoiseDemoView()
            }
            Tab("fBM", systemImage: "function") {
                FbmDemoView()
            }
            Tab("Warp", systemImage: "waveform.path.ecg") {
                WarpDemoView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
}
