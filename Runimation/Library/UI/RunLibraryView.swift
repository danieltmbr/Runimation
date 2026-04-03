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
/// GPX files are imported via the file picker (iOS) and drag-and-drop (macOS).
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

    @Environment(\.deleteRun)
    private var deleteRun


    // MARK: - Bindings

    @Binding var isPresented: Bool

    #if os(macOS)
    @Binding var statsPath: [RunEntry]
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
                allowedContentTypes: [gpxUTType],
                allowsMultipleSelection: true
            ) { result in
                handleImportResult(result)
            }
            .onDrop(of: [gpxUTType, .fileURL], isTargeted: $isDragTargeted) { providers in
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
                        if record.entryID == entries.last?.entryID {
                            loadNextPage()
                        }
                    }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func libraryRow(_ record: RunRecord) -> some View {
        HStack {
            PlayRunButton(record, onPlayed: { isPresented = false }) { _ in
                RunInfoView(
                    name: record.name,
                    date: record.date,
                    distance: record.distance,
                    duration: record.duration
                )
                .runInfoStyle(.compact)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Menu {
                #if os(macOS)
                Button {
                    statsPath.append(RunEntry(id: record.entryID))
                    isPresented = false
                } label: {
                    Label("Stats", systemImage: "chart.bar")
                }
                #else
                NavigationLink(value: RunEntry(id: record.entryID)) {
                    Label("Stats", systemImage: "chart.bar")
                }
                #endif

                Button {} label: {
                    Label("Favourite", systemImage: "heart")
                }
                .disabled(true)

                Button {} label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(true)

                Divider()

                Button(role: .destructive) {
                    deleteRun(record)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .padding(.vertical, 12)
                    .padding(.leading, 12)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteRun(record)
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
        for url in urls { importFile(url) }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(gpxUTType.identifier) {
                provider.loadItem(forTypeIdentifier: gpxUTType.identifier) { item, _ in
                    guard let url = item as? URL else { return }
                    Task { @MainActor in self.importFile(url) }
                }
                handled = true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          url.pathExtension.lowercased() == "gpx" else { return }
                    Task { @MainActor in self.importFile(url) }
                }
                handled = true
            }
        }
        return handled
    }

    // MARK: - Helpers

    private var gpxUTType: UTType {
        UTType(filenameExtension: "gpx") ?? .xml
    }
}
