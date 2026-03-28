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

    @Environment(RunLibrary.self)
    private var library

    @State
    private var showLibrary = false

    @State
    private var showNowPlaying = false

    #if os(macOS)
    @State
    private var navigationPath: [RunEntry] = []
    #endif

    @State
    private var sheetHeight: CGFloat = 0

    @NowPlaying var nowPlaying

    #if os(iOS)
    @State
    private var showCustomisation = false
    #endif

    #if os(macOS)
    @Environment(\.openWindow)
    private var openWindow
    #endif
    
    var body: some View {
        content
#if os(iOS)
            .sheet(isPresented: $showLibrary) {
                RunLibraryView(isPresented: $showLibrary)
            }
            .sheet(isPresented: $showNowPlaying) {
                NowPlayingSheet()
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
            }
    }
    
    private var content: some View {
#if os(macOS)
        NavigationStack(path: $navigationPath) {
            VisualiserView()
                .navigationDestination(for: RunEntry.self) { RunStatsDestination(entry: $0) }
                .toolbar { topToolbarItems }
                .ignoresSafeArea()
                .safeAreaInset(edge: .bottom) { bottomBar }
        }
#else
        NavigationStack {
            VisualiserView()
                .toolbar { topToolbarItems }
                .ignoresSafeArea()
                .safeAreaInset(edge: .bottom) { bottomBar }
        }
#endif
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
            RunLibraryView(isPresented: $showLibrary, statsPath: $navigationPath)
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
        guard nowPlaying.isSedentary else { return }
        guard let record = library.lastPlayedRecord() else {
            showLibrary = true
            return
        }
        await nowPlaying.play(record)
    }
}

#Preview {
    ContentView()
}
