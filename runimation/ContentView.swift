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
/// `autoOpenLibrary` controls whether the library is shown on first launch when no
/// previous run exists. Set to `false` in viewer windows that open a specific `.runi`
/// file — those windows receive their run via `onOpenURL` instead.
///
struct ContentView: View {

    private let autoOpenLibrary: Bool

    init(autoOpenLibrary: Bool = true) {
        self.autoOpenLibrary = autoOpenLibrary
    }

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

    @State
    private var viewportSize: CGSize = .zero

    @NowPlaying var nowPlaying

    /// Set after a `.runi` file open — triggers the save-to-library confirmation alert.
    /// Not used in viewer windows (`autoOpenLibrary == false`) where the library is ephemeral.
    @State
    private var importedRecord: RunRecord?

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
            .alert(
                "Save to Library?",
                isPresented: Binding(get: { importedRecord != nil }, set: { if !$0 { importedRecord = nil } })
            ) {
                Button("Save") { importedRecord = nil }
                Button("Remove", role: .destructive) {
                    if let record = importedRecord { library.delete(record) }
                    importedRecord = nil
                }
            } message: {
                if let record = importedRecord {
                    Text("Keep \(record.name) in your library?")
                }
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
                .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        }
        .onOpenURL { url in
            guard url.pathExtension == "runi" else { return }
            handleRuniImport(url: url)
        }
#else
        NavigationStack {
            VisualiserView()
                .toolbar { topToolbarItems }
                .ignoresSafeArea()
                .safeAreaInset(edge: .bottom) { bottomBar }
                .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        }
        .onOpenURL { url in
            guard url.pathExtension == "runi" else { return }
            handleRuniImport(url: url)
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
            ExportButton(viewportSize: viewportSize)
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

    // MARK: - .runi Import

    /// Decodes a `.runi` file, plays it immediately, then (in the main window) asks if
    /// the user wants to keep it in the library.
    ///
    /// Security-scoped resource access is started unconditionally — on iOS, AirDrop
    /// file URLs don't require it and `startAccessingSecurityScopedResource` returns
    /// `false`, but the file is still readable. Guarding on the return value would
    /// cause a silent failure on iOS.
    ///
    private func handleRuniImport(url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url),
              let document = try? JSONDecoder().decode(RuniDocument.self, from: data)
        else { return }

        Task {
            let record = library.importRuniDocument(document)
            await nowPlaying.play(record)
            // Only prompt to save in the main persistent-library window.
            if autoOpenLibrary {
                importedRecord = record
            }
        }
    }

    // MARK: - Initial Load

    private func restoreLastPlayedRun() async {
        // Viewer windows receive their run via onOpenURL — skip auto-library-restore.
        guard autoOpenLibrary else { return }
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
