import CoreKit
import RunKit
import RunUI
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

    /// iOS: navigation path for stats within the library sheet.
    @State
    private var libraryNavPath: [LibraryEntry] = []

    /// macOS: entry to show in stats destination on the main NavigationStack.
    @State
    private var statsEntry: LibraryEntry?

    @Environment(RunLibrary.self)
    private var library

    private var hasRun: Bool {
        !player.run.metrics.segments.isEmpty
    }

    var body: some View {
        NavigationStack {
            VisualiserView(showInspector: $showInspector)
                .toolbar { topToolbarItems }
                .safeAreaInset(edge: .bottom) { bottomBar }
                .navigationDestination(item: $statsEntry) { entry in
                    RunStatsDestination(entry: entry)
                        .library(library, player: player)
                }
        }
        .player(player)
        #if os(iOS)
        .sheet(isPresented: $showLibrary) { librarySheet }
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
        .task {
            await loadBundledRunIfNeeded()
            if !hasRun { showLibrary = true }
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
            RunLibraryView(
                onRunLoaded: { showLibrary = false },
                onShowStats: { entry in
                    showLibrary = false
                    statsEntry = entry
                }
            )
            .library(library, player: player)
            .player(player)
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

    // MARK: - Library Sheet (iOS)

    #if os(iOS)
    private var librarySheet: some View {
        NavigationStack(path: $libraryNavPath) {
            RunLibraryView(
                onRunLoaded: { showLibrary = false },
                onShowStats: { entry in libraryNavPath.append(entry) }
            )
            .navigationTitle("Run Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        showLibrary = false
                    }
                }
            }
            .navigationDestination(for: LibraryEntry.self) { entry in
                RunStatsDestination(entry: entry)
                    .environment(library)
            }
        }
        .library(library, player: player)
        .player(player)
    }
    #endif

    // MARK: - Initial Load

    private func loadBundledRunIfNeeded() async {
        guard !hasRun else { return }
        let track = await Task.detached {
            GPX.Parser().parse(fileNamed: "run-01").first
        }.value
        guard let track else { return }
        try? await player.setRun(track)
    }
}

#Preview {
    ContentView()
}
