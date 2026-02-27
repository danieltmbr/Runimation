import SwiftUI

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
                        if let run = player.runs?.run(for: .metrics) {
                            RunMetricsView(run: run)
                        } else {
                            ContentUnavailableView(
                                "Run Unavailable",
                                systemImage: "chart.xyaxis.line",
                                description: Text("The run data could not be loaded.")
                            )
                        }
                    } else {
                        ProgressView("Loading run data...")
                    }
                }
            }

            TabSection("Learnings") {
                Tab("Noise", systemImage: "waveform", value: "noise") {
                    NoiseView()
                }
                Tab("fBM", systemImage: "function", value: "fbm") {
                    FbmView()
                }
                Tab("Warp", systemImage: "waveform.path.ecg", value: "warp") {
                    WarpView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
#if os(iOS)
        .tabViewBottomAccessory(isEnabled: selectedTab == "visualiser" && player != nil) {
            if let player {
                PlayerControlsView(showInspector: $showInspector)
                    .player(player)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
#endif
        .task {
            if player == nil {
                player = await Task.detached {
                    let gpxParser = GPX.Parser()
                    guard let track = gpxParser.parse(fileNamed: "run-01").first else { return nil }
                    let p = await RunPlayer(
                        parser: Run.Parser(),
                        transformer: TransformerChain.guassian.speedWeighted
                    )
                    p.setRun(track)
                    return p
                }.value
            }
        }
    }
}

#Preview {
    ContentView()
}
