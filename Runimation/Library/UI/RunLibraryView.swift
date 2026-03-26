import RunUI
import SwiftUI
import UniformTypeIdentifiers

/// Unified run library listing Strava runs and imported GPX files.
///
/// Displays all entries as compact `RunInfoView` rows. Tapping a row loads the
/// run into the player and calls `onRunLoaded`. A trailing three-dots menu
/// offers Stats, Favourite (disabled), Share (disabled), and Delete.
///
/// GPX files are imported via the file picker (iOS) and drag-and-drop (macOS).
///
/// Requires `.library(_:player:)` in the view hierarchy.
///
struct RunLibraryView: View {

    // MARK: - Library State

    @LibraryState(\.entries)
    private var entries

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

    @Environment(\.deleteEntry)
    private var deleteEntry

    @Environment(\.playEntry)
    private var playEntry

    // MARK: - Callbacks

    /// Called after a run has been successfully loaded into the player.
    let onRunLoaded: @MainActor () -> Void

    /// Called when the user requests the stats screen for an entry.
    /// The caller is responsible for platform-appropriate navigation.
    let onShowStats: @MainActor (LibraryEntry) -> Void

    // MARK: - State

    @State
    private var isShowingFilePicker = false

    @State
    private var isDragTargeted = false

    // MARK: - Body

    var body: some View {
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
            List(entries) { entry in
                libraryRow(entry)
                    .onAppear {
                        if entry.id == entries.last?.id {
                            loadNextPage()
                        }
                    }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func libraryRow(_ entry: LibraryEntry) -> some View {
        Button {
            playEntry(entry) { onRunLoaded() }
        } label: {
            RunEntryRow(entry: entry) { entry in
                Button {
                    onShowStats(entry)
                } label: {
                    Label("Stats", systemImage: "chart.bar")
                }

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
                    deleteEntry(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            importButton
        }
        if isConnected {
            ToolbarItem(placement: .automatic) {
                DisconnectButton()
            }
        }
    }

    private var importButton: some View {
        Button {
            isShowingFilePicker = true
        } label: {
            Label("Import File", systemImage: "square.and.arrow.down")
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
