import SwiftUI
import RunKit
import RunUI

struct ContentView: View {
    
    @State
    private var player: RunPlayer?
    
    @State
    private var showInspector = false
    
    @State
    private var selectedTab: String = "visualiser"

    var body: some View {
        TabView(selection: $selectedTab) {
            TabSection("Runs") {
                Tab("Visualisation", systemImage: "sparkles", value: "visualiser") {
                    if let player {
                        VisualiserView(showInspector: $showInspector)
                            .player(player)
                    } else {
                        ProgressView("Loading run data...")
                    }
                }
                Tab("Metrics", systemImage: "chart.xyaxis.line", value: "metrics") {
                    if let player {
                        RunMetricsView(run: player.runs.run(for: .metrics))
                    } else {
                        ProgressView("Loading run data...")
                    }
                }
            }

            TabSection("Learnings") {
                Tab("Noise", systemImage: "waveform", value: "noise") {
                    NoiseDemoView()
                }
                Tab("fBM", systemImage: "function", value: "fbm") {
                    FbmDemoView()
                }
                Tab("Warp", systemImage: "waveform.path.ecg", value: "warp") {
                    WarpDemoView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
#if os(iOS)
        .tabViewBottomAccessory(isEnabled: selectedTab == "visualiser" && player != nil) {
            if let player {
                PlaybackControls()
                    .playbackControlsStyle(.compact)
                    .onTapGesture { showInspector.toggle() }
                    .player(player)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
#endif
        .task {
            if player == nil {
                player = try? await Task.detached {
                    let gpxParser = GPX.Parser()
                    guard let track = gpxParser.parse(fileNamed: "run-01").first else { return nil }
                    let p = await RunPlayer(
                        transformers: [.gaussian(), .speedWeighted(), .waveSampling()]
                    )
                    try await p.setRun(track)
                    return p
                }.value
            }
        }
    }
}

#Preview {
    ContentView()
}
