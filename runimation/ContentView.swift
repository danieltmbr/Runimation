import SwiftUI

struct ContentView: View {
    @State private var player: RunPlayer?

    @State private var showPlayerSheet = false
    @State private var selectedPanel: PlayerPanel? = nil
    
    @State
    private var baseH: Double = 0.5
    
    @State
    private var octaves: Double = 6.0

    var body: some View {
        TabView {
            TabSection("Runs") {
                Tab("Visualisation", systemImage: "sparkles") {
                    if let player {
                        VisualiserView(baseH: $baseH, octaves: $octaves)
                            .player(player)
                    } else {
                        ProgressView("Loading run data...")
                    }
                }
                Tab("Metrics", systemImage: "chart.xyaxis.line") {
                    if let player {
                        RunMetricsView()
                            .player(player)
                    } else {
                        ProgressView("Loading run data...")
                    }
                }
            }

            TabSection("Learnings") {
                Tab("Noise", systemImage: "waveform") {
                    NoiseView()
                }
                Tab("fBM", systemImage: "function") {
                    FbmView()
                }
                Tab("Warp", systemImage: "waveform.path.ecg") {
                    WarpView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
#if os(iOS)
        .tabViewBottomAccessory(isEnabled: player != nil && !showPlayerSheet) {
            if let player {
                PlayerControlsView(showSheet: $showPlayerSheet)
                    .player(player)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
#else
        .toolbarVisibility(.hidden, for: .windowToolbar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let player, !showPlayerSheet {
                HStack {
                    Spacer(minLength: 0)
                    PlayerControlsView(showSheet: $showPlayerSheet)
                        .player(player)
                        .frame(width: 320)
                        .glassEffect()
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 12)
            }
        }
#endif
        .sheet(isPresented: $showPlayerSheet) {
            if let player {
                PlayerSheetView(
                    baseH: $baseH,
                    octaves: $octaves,
                    selectedPanel: $selectedPanel
                )
                .player(player)
            }
        }
        .task {
            if player == nil {
                player = await Task.detached {
                    let gpxParser = GPX.Parser()
                    guard let track = gpxParser.parse(fileNamed: "run-01").first else { return nil }
                    let p = RunPlayer(
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
