import SwiftUI

/// Displays the active transformer chain and the available catalog,
/// allowing the user to reorder, remove, and add transformers.
///
/// - The **Applied** section reflects `RunPlayer.selectedTransformers` with
///   drag-to-reorder and swipe-to-delete. Tapping ℹ️ opens an editable sheet.
/// - The **Available** section lists the catalog. Tapping `+` appends a fresh
///   instance (new UUID) to the chain. Tapping ℹ️ opens a read-only sheet.
///
struct TransformerListView: View {

    @PlayerState(\.selectedTransformers)
    private var selectedTransformers

    @State
    private var activeSheet: ActiveSheet? = nil

    var body: some View {
        List {
            appliedSection
            availableSection
        }
        #if os(iOS)
        .environment(\.editMode, .constant(.active))
        #endif
        .navigationTitle("Transformers")
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Sections

    private var appliedSection: some View {
        Section("Applied") {
            if selectedTransformers.isEmpty {
                Text("No transformers applied")
                    .foregroundStyle(.secondary)
                    .deleteDisabled(true)
                    .moveDisabled(true)
            }
            ForEach(Array(selectedTransformers.enumerated()), id: \.element.id) { index, option in
                appliedRow(option: option, index: index)
            }
            .onMove { from, to in
                selectedTransformers.move(fromOffsets: from, toOffset: to)
            }
            .onDelete { offsets in
                selectedTransformers.remove(atOffsets: offsets)
            }
        }
    }

    private var availableSection: some View {
        Section("Available") {
            ForEach(RunTransformerOption.catalog) { option in
                availableRow(option: option)
            }
            .moveDisabled(true)
            .deleteDisabled(true)
        }
    }

    // MARK: - Rows

    private func appliedRow(option: RunTransformerOption, index: Int) -> some View {
        HStack {
            Text(option.label)
            Spacer()
            Button {
                activeSheet = .applied(index)
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
        }
    }

    private func availableRow(option: RunTransformerOption) -> some View {
        HStack {
            Text(option.label)
            Spacer()
            Button {
                activeSheet = .catalog(option)
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            Button {
                selectedTransformers.append(.init(
                    label: option.label,
                    description: option.description,
                    transformer: option.transformer
                ))
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .applied(let index):
            if index < selectedTransformers.count {
                TransformerInfoSheet(
                    option: selectedTransformers[index],
                    binding: $selectedTransformers[index]
                )
            }
        case .catalog(let option):
            TransformerInfoSheet(option: option)
        }
    }
}

// MARK: - ActiveSheet

private extension TransformerListView {

    enum ActiveSheet: Identifiable {
        case applied(Int)
        case catalog(RunTransformerOption)

        var id: String {
            switch self {
            case .applied(let index): return "applied-\(index)"
            case .catalog(let option): return "catalog-\(option.id.uuidString)"
            }
        }
    }
}
