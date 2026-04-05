import RunUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Unified run library listing Strava runs and imported GPX files.
///
/// On iOS, presented as a sheet with its own `NavigationStack` so stats can
/// push within the sheet. On macOS, presented as a popover with no internal
/// stack — "Stats" appends to the caller's `statsPath` binding so navigation
/// happens in the main window's `NavigationStack`.
///
/// The parent controls visibility via `isPresented`. On macOS, the parent must
/// also pass `statsPath` and own a `navigationDestination(for: RunEntry.self)`.
///
/// GPX and `.runi` files are imported via the file picker (iOS) and drag-and-drop (macOS).
///
/// Requires `.library(_:)` and `.player(_:)` in the view hierarchy.
///
struct RunLibraryView: View {

    // MARK: - Library State

    @Query(sort: \RunRecord.date, order: .reverse)
    private var entries: [RunRecord]

    @LibraryState(\.isLoading)
    private var isLoading

    @LibraryState(\.isConnected)
    private var isConnected

    // MARK: - Library Actions

    @Environment(\.refreshLibrary)
    private var refreshLibrary

    @Environment(\.loadNextPage)
    private var loadNextPage

    @Environment(\.importFile)
    private var importFile

    @Environment(\.importDocument)
    private var importDocument

    // MARK: - Bindings

    @Binding var isPresented: Bool

    #if os(macOS)
    @Binding var statsPath: [RunEntry]

    /// Use in `NavigationSplitView` sidebar where the view is persistent — no dismiss needed.
    init(statsPath: Binding<[RunEntry]>) {
        _isPresented = .constant(false)
        _statsPath = statsPath
    }
    #endif

    // MARK: - State

    #if !os(macOS)
    @State
    private var path: [RunEntry] = []
    #endif

    @State
    private var isShowingFilePicker = false

    @State
    private var isDragTargeted = false


    // MARK: - Body

    var body: some View {
        #if os(macOS)
        libraryContent
        #else
        NavigationStack(path: $path) {
            libraryContent
                .navigationDestination(for: RunEntry.self) { RunStatsDestination(entry: $0) }
        }
        #endif
    }

    private var libraryContent: some View {
        libraryList
            .navigationTitle("Run Library")
            .toolbar { toolbarContent }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [gpxUTType, .runi],
                allowsMultipleSelection: true
            ) { result in
                handleImportResult(result)
            }
            .onDrop(of: [gpxUTType, .runi, .fileURL], isTargeted: $isDragTargeted) { providers in
                handleDrop(providers)
            }
            .overlay(dropOverlay)
            .task { await loadIfNeeded() }
    }

    // MARK: - List

    @ViewBuilder
    private var libraryList: some View {
        if isLoading && entries.isEmpty {
            ProgressView("Loading runs…")
        } else if entries.isEmpty {
            LibraryEmptyView(onImport: { isShowingFilePicker = true })
        } else {
            List(entries) { record in
                libraryRow(record)
                    .onAppear {
                        guard record.entry == entries.last?.entry else { return }
                        loadNextPage()
                    }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func libraryRow(_ record: RunRecord) -> some View {
        RunEntryRow(record: record) { record in
            RunMenuActions(run: record.entry)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            DeleteRunButton(run: record.entry)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) { isPresented = false }
        }
        #endif
        ToolbarItem(placement: .primaryAction) {
            moreMenu
        }
    }

    private var moreMenu: some View {
        Menu {
            Button {
                isShowingFilePicker = true
            } label: {
                Label("Import File", systemImage: "square.and.arrow.down")
            }

            if isConnected {
                DisconnectButton()
            } else {
                ConnectButton()
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }


    // MARK: - Drop Overlay

    @ViewBuilder
    private var dropOverlay: some View {
        if isDragTargeted {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.blue, lineWidth: 2)
                .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    Label("Drop run file", systemImage: "arrow.down.doc")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                .padding()
        }
    }

    // MARK: - Actions

    private func loadIfNeeded() async {
        guard isConnected && entries.isEmpty else { return }
        refreshLibrary()
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        for url in urls { importURL(url) }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.runi.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.runi.identifier) { item, _ in
                    guard let url = item as? URL else { return }
                    Task { @MainActor in try? self.importDocument(url) }
                }
                handled = true
            } else if provider.hasItemConformingToTypeIdentifier(gpxUTType.identifier) {
                provider.loadItem(forTypeIdentifier: gpxUTType.identifier) { item, _ in
                    guard let url = item as? URL else { return }
                    Task { @MainActor in self.importFile(url) }
                }
                handled = true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil)
                    else { return }
                    Task { @MainActor in self.importURL(url) }
                }
                handled = true
            }
        }
        return handled
    }

    private func importURL(_ url: URL) {
        if url.pathExtension.lowercased() == "runi" {
            Task { try? importDocument(url) }
        } else {
            importFile(url)
        }
    }

    // MARK: - Helpers

    private var gpxUTType: UTType {
        UTType(filenameExtension: "gpx") ?? .xml
    }
}
