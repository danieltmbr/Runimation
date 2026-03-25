import CoreKit
import RunKit
import RunUI
import StravaKit
import SwiftUI

/// Root view of the Runimation app.
///
/// Owns the `RunPlayer` and coordinates top-level navigation: the Run Library,
/// the Customisation Panel (inspector), and the Share sheet. The full-screen
/// `VisualiserView` is always the background experience.
///
struct ContentView: View {

    @State
    private var player = RunPlayer(transformers: [GuassianRun()])

    @State
    private var showInspector = false

    @State
    private var showLibrary = false

    @State
    private var showNowPlaying = false
    
    @State
    private var sheetHeight: CGFloat = 0

    @Environment(StravaClient.self)
    private var stravaClient

    private var hasRun: Bool {
        !player.run.metrics.segments.isEmpty
    }

    var body: some View {
        NavigationStack {
            VisualiserView(showInspector: $showInspector)
                .toolbar { topToolbarItems }
                .safeAreaInset(edge: .bottom) { bottomBar }
        }
        .player(player)
        .sheet(isPresented: $showLibrary) { librarySheet }
        #if os(iOS)
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingSheet()
                .player(player)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newValue in
                    sheetHeight = newValue
                }
                .presentationDetents([.height(sheetHeight)])
                .presentationDragIndicator(.automatic)
        }
        #endif
        .task { await loadBundledRunIfNeeded() }
        .onAppear { autoOpenLibraryIfEmpty() }
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
    }

    private var shareButton: some View {
        Button { } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .disabled(true)
    }

    private var customisationButton: some View {
        Button {
            showInspector.toggle()
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

    // MARK: - Library Sheet

    private var librarySheet: some View {
        NavigationStack {
            StravaRunsView { showLibrary = false }
                .navigationTitle("Run Library")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showLibrary = false }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
        .player(player)
        .environment(stravaClient)
    }

    // MARK: - Initial Load

    private func loadBundledRunIfNeeded() async {
        guard !hasRun else { return }
        let track = await Task.detached {
            GPX.Parser().parse(fileNamed: "run-01").first
        }.value
        guard let track else { return }
        try? await player.setRun(track)
    }

    private func autoOpenLibraryIfEmpty() {
        if !hasRun { showLibrary = true }
    }
}

#Preview {
    ContentView()
}
