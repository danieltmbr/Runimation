import Animations
import RunKit
import RunUI
import StravaKit
import SwiftUI

struct ContentView: View {

    @State
    private var player = RunPlayer(
        transformers: [GuassianRun()]
    )

    @State
    private var stravaClient = StravaClient()

    @State
    private var showInspector = false

    @State
    private var selectedTab: String = "visualiser"

    private var hasRun: Bool {
        !player.run.metrics.segments.isEmpty
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TabSection("Runs") {
                Tab("Visualisation", systemImage: "sparkles", value: "visualiser") {
                    if hasRun {
                        VisualiserView(showInspector: $showInspector)
                    } else {
                        ProgressView("Loading run data…")
                    }
                }
                Tab("Path", systemImage: "point.bottomleft.forward.to.arrow.triangle.scurvepath", value: "path") {
                    if hasRun {
                        PathView()
                    } else {
                        ProgressView("Loading run data…")
                    }
                }
                Tab("Metrics", systemImage: "chart.xyaxis.line", value: "metrics") {
                    RunMetricsView(run: player.run.metrics)
                }
                Tab("Library", systemImage: "figure.run", value: "library") {
                    StravaRunsView { selectedTab = "visualiser" }
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
        .player(player)
        .environment(stravaClient)
#if os(iOS)
        .tabViewBottomAccessory(isEnabled: selectedTab == "visualiser" && hasRun) {
            PlaybackControls()
                .playbackControlsStyle(.compact)
                .onTapGesture { showInspector.toggle() }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
#endif
        .task {
            guard !hasRun else { return }
            let track = await Task.detached {
                GPX.Parser().parse(fileNamed: "run-01").first
            }.value
            guard let track else { return }
            try? await player.setRun(track)
        }
    }
}

#Preview {
    ContentView()
}
