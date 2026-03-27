import CoreKit
import RunKit
import RunUI
import SwiftUI
import Visualiser

/// Root view of the Runimation app.
///
/// Coordinates top-level navigation: the Run Library, the Customisation Panel,
/// and the Share sheet. The full-screen `VisualiserView` is always the background.
///
struct ContentView: View {

    @Environment(RunPlayer.self)
    private var player

    @Environment(RunLibrary.self)
    private var library

    @Environment(VisualisationModel.self)
    private var visualisationModel

    @Environment(\.loadRun)
    private var loadRun

    @Environment(\.scenePhase)
    private var scenePhase

    @State
    private var showLibrary = false

    @State
    private var showNowPlaying = false

    @State
    private var sheetHeight: CGFloat = 0

    #if os(iOS)
    @State
    private var showCustomisation = false
    #endif

    #if os(macOS)
    @Environment(\.openWindow)
    private var openWindow
    #endif

    private var hasRun: Bool {
        !player.run.metrics.segments.isEmpty
    }

    var body: some View {
        NavigationStack {
            VisualiserView()
                .toolbar { topToolbarItems }
                .ignoresSafeArea()
                .safeAreaInset(edge: .bottom) { bottomBar }
        }
        #if os(iOS)
        .sheet(isPresented: $showLibrary) {
            RunLibraryView(isPresented: $showLibrary)
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingSheet()
                .player(player)
                .presentationDetents([.height(sheetHeight)])
                .presentationDragIndicator(.automatic)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
        }
        .sheet(isPresented: $showCustomisation) {
            CustomisationPanel()
        }
        #endif
        .task {
            await restoreLastPlayedRun()
            // Show library only if no run is loaded and no async restore is in progress.
            // (A lastPlayedRecord means restoreLastPlayedRun is loading the run.)
            if !hasRun && library.lastPlayedRecord() == nil { showLibrary = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                library.saveCurrentConfig(
                    visualisation: visualisationModel.current,
                    transformers: player.transformers,
                    interpolator: player.interpolator,
                    duration: player.duration
                )
            }
        }
    }

    // MARK: - Top Toolbar

    @ToolbarContentBuilder
    private var topToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            libraryButton
        }
        ToolbarItem(placement: .primaryAction) {
            shareButton
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            playbackControls
                .glassEffect(in: Capsule())
#if os(iOS)
            Spacer()
#endif
            customisationButton
                .glassEffect(in: Circle())
        }
#if os(iOS)
        .padding(.horizontal)
#else
        .padding()
#endif
    }

    // MARK: - Toolbar Items

    private var libraryButton: some View {
        Button {
            showLibrary = true
        } label: {
            Label("Run Library", systemImage: "figure.run")
        }
        #if os(macOS)
        .popover(isPresented: $showLibrary) {
            RunLibraryView(isPresented: $showLibrary)
                .frame(minWidth: 360, minHeight: 450)
        }
        #endif
    }

    private var shareButton: some View {
        Button { } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .disabled(true)
    }

    private var customisationButton: some View {
        Button {
            #if os(macOS)
            openWindow(id: "customisation")
            #else
            showCustomisation = true
            #endif
        } label: {
            Label("Customise", systemImage: "slider.horizontal.3")
                .padding(10)
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .imageScale(.large)
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var playbackControls: some View {
        #if os(iOS)
        PlaybackControls()
            .playbackControlsStyle(.compact)
            .contentShape(Capsule())
            .onTapGesture { showNowPlaying = true }
        #else
        PlaybackControls()
            .playbackControlsStyle(.regular)
        #endif
    }

    // MARK: - Initial Load

    private func restoreLastPlayedRun() async {
        guard !hasRun else { return }
        if let record = library.lastPlayedRecord() {
            guard let run = try? await loadRun(record) else { return }
            try? await player.setRun(run)
            restoreConfig(for: record)
            library.markAsPlaying(record)
            return
        }
        // First launch — load bundled run and persist it
        let track = await Task.detached {
            GPX.Parser().parse(fileNamed: "run-01").first
        }.value
        guard let track else { return }
        library.persistBundledRun(track: track, name: "run-01")
        try? await player.setRun(track)
    }

    private func restoreConfig(for record: RunRecord) {
        if record.hasConfig {
            if let vis = record.loadVisualisationConfig() { visualisationModel.current = vis }
            let transformers = record.loadTransformersConfig()
            if !transformers.isEmpty { player.transformers = transformers }
            if let interpolator = record.loadInterpolatorConfig() { player.interpolator = interpolator }
            if let duration = record.loadDurationConfig() { player.duration = duration }
        } else if let last = library.lastUsedConfig() {
            visualisationModel.current = last.visualisation
            player.transformers = last.transformers
            player.interpolator = last.interpolator
            player.duration = last.duration
        }
    }
}

#Preview {
    ContentView()
}
