import SwiftUI
import Visualiser

/// Root view for the RuniDemos app. Presents all shader learning demos
/// in a sidebar-style TabView so each can be explored independently.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Colors", systemImage: "paintpalette") {
                ColorsDemoView()
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
