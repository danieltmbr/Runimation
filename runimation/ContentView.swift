import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NoiseView()
                .tabItem {
                    Label("Noise", systemImage: "waveform")
                }
                .tag(0)

            FbmView()
                .tabItem {
                    Label("fBm", systemImage: "scribble.variable")
                }
                .tag(1)
            
            WarpView()
                .tabItem {
                    Label("Warp", systemImage: "scribble.variable")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
