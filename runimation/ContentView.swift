import SwiftUI

struct ContentView: View {
    @State private var engine: PlaybackEngine?

    var body: some View {
        TabView {
            TabSection("Runs") {
                Tab("Metrics", systemImage: "chart.xyaxis.line") {
                    if let engine {
                        RunMetricsView(engine: engine)
                    } else {
                        ProgressView("Loading run data...")
                    }
                }
                Tab("Visualisation", systemImage: "sparkles") {
                    if let engine {
                        RunView(engine: engine)
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
                Tab("Colorings", systemImage: "paintpalette") {
                    ColoringView()
                }
                Tab("Animations", systemImage: "play.circle") {
                    AnimationExplorerView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        // Drives engine.update() regardless of which tab is visible.
        .background {
            if let engine {
                TimelineView(.animation(paused: !engine.isPlaying)) { timeline in
                    Color.clear
                        .onChange(of: timeline.date) { _, date in
                            engine.update(now: date)
                        }
                }
            }
        }
        .task {
            if engine == nil {
                engine = await Task.detached {
                    guard let track = GPXParser.parse(fileNamed: "run-01") else { return nil }
                    return PlaybackEngine(runData: RunData(track: track))
                }.value
            }
        }
    }
}

#Preview {
    ContentView()
}
