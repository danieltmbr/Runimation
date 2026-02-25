import SwiftUI

struct ContentView: View {
    @State private var player: RunPlayer?

    var body: some View {
        TabView {
            TabSection("Runs") {
                Tab("Metrics", systemImage: "chart.xyaxis.line") {
                    if let player {
                        RunMetricsView(player: player)
                    } else {
                        ProgressView("Loading run data...")
                    }
                }
                Tab("Visualisation", systemImage: "sparkles") {
                    if let player {
                        RunPlayerView(player: player)
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
