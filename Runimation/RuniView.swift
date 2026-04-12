import CoreUI
import RunKit
import RunUI
import RuniTransfer
import SwiftUI
import VisualiserUI

struct RuniView: View {

    @Navigation(\.autoRestore)
    private var autoRestore

    @Navigation(\.library.columnVisibility)
    private var columnVisibility

    @Navigation(\.importer.importedItem)
    private var importedItem

    @Navigation(\.library.statsPath)
    private var stats

    @LibraryState(\.lastPlayedItem)
    private var lastPlayedItem

    @Environment(\.importFile)
    private var importFile

    @NowPlaying
    private var nowPlaying

    @State
    private var viewportSize: CGSize = .zero

#if os(iOS)
    @Navigation(\.library.showLibrary)
    private var showLibrary

    @Navigation(\.player.showNowPlaying)
    private var showNowPlaying

    @Navigation(\.player.showCustomisation)
    private var showCustomisation

    @State
    private var sheetHeight: CGFloat = 0
#endif

    var body: some View {
        content
            .onOpenURL { handleURL($0) }
            .task { await restoreLastPlayedRun() }
            .importDialogue()
            .exportDialogue(viewportSize: viewportSize)
    }

    // MARK: - Layout

    private var content: some View {
#if os(macOS)
        NavigationSplitView(columnVisibility: $columnVisibility) {
            RunLibraryView(statsPath: $stats)
        } detail: {
            detail
        }
#else
        detail
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
    }

    private var detail: some View {
        NavigationStack(path: $stats) {
            VisualiserView()
                .navigationDestination(for: RunItem.self) { RunStatsDestination(item: $0) }
                .toolbar { topToolbarItems }
                .ignoresSafeArea()
                .safeAreaInset(edge: .bottom) { bottomBar }
                .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        }
    }

    // MARK: - Top Toolbar

    @ToolbarContentBuilder
    private var topToolbarItems: some ToolbarContent {
#if os(iOS)
        ToolbarItem(placement: .navigation) {
            LibraryToggle()
        }
#endif
        ToolbarItem(placement: .primaryAction) {
            ExportButton()
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
            CustomisationToggle()
                .glassEffect(in: Circle())
        }
#if os(iOS)
        .padding(.horizontal)
#else
        .padding()
#endif
    }

    // MARK: - Toolbar Items

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

    /// Imports a `.runi` file, plays it immediately, then (in the main window)
    /// prompts the user whether to keep it in the library.
    ///
    private func handleURL(_ url: URL) {
        guard url.pathExtension == "runi" else { return }
        Task {
            guard let item = try? await importFile(url) else { return }
            await nowPlaying.play(item)
            if autoRestore { importedItem = item }
        }
    }

    // MARK: - Initial Load

    private func restoreLastPlayedRun() async {
        guard autoRestore else { return }
        guard nowPlaying.isSedentary else { return }
        guard let item = lastPlayedItem else {
#if os(iOS)
            showLibrary = true
#endif
            return
        }
        await nowPlaying.play(item)
    }
}

#Preview {
    RuniView()
}
