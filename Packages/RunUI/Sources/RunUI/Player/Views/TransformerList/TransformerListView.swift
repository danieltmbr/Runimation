import SwiftUI
import RunKit

/// Displays the active transformer chain and the available catalog,
/// allowing the user to reorder, remove, and add transformers.
///
/// - The **Applied** section reflects `RunPlayer.transformers` with
///   drag-to-reorder and swipe-to-delete. Tapping ℹ️ opens an editable sheet.
/// - The **Available** section lists the catalog. Tapping `+` appends a fresh
///   instance (new UUID) to the chain. Tapping ℹ️ opens a read-only sheet.
///
public struct TransformerListView: View {

    @PlayerState(\.transformers)
    private var transformers

    @State
    private var items: [Item<any RunTransformer>] = []

    @State
    private var activeSheet: ActiveSheet? = nil

    private static let catalog: [Item<any RunTransformer>] = [
        Item(value: GuassianRun() as any RunTransformer),
        Item(value: SpeedWeightedRun() as any RunTransformer),
        Item(value: WaveSamplingTransformer() as any RunTransformer),
    ]

    public init() {}

    public var body: some View {
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
        .onAppear {
            items = transformers.map { Item(value: $0) }
        }
    }

    // MARK: - Sections

    private var appliedSection: some View {
        Section("Applied") {
            if items.isEmpty {
                Text("No transformers applied")
                    .foregroundStyle(.secondary)
                    .deleteDisabled(true)
                    .moveDisabled(true)
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                appliedRow(item: item, index: index)
            }
            .onMove { from, to in
                items.move(fromOffsets: from, toOffset: to)
                transformers = items.map(\.value)
            }
            .onDelete { offsets in
                items.remove(atOffsets: offsets)
                transformers = items.map(\.value)
            }
        }
    }

    private var availableSection: some View {
        Section("Available") {
            ForEach(Self.catalog) { catalogItem in
                availableRow(item: catalogItem)
            }
            .moveDisabled(true)
            .deleteDisabled(true)
        }
    }

    // MARK: - Rows

    private func appliedRow(item: Item<any RunTransformer>, index: Int) -> some View {
        HStack {
            Text(item.label)
            Spacer()
            Button {
                activeSheet = .applied(index)
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
        }
    }

    private func availableRow(item: Item<any RunTransformer>) -> some View {
        HStack {
            Text(item.label)
            Spacer()
            Button {
                activeSheet = .catalog(item)
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            Button {
                items.append(Item(value: item.value))
                transformers = items.map(\.value)
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
            if index < items.count {
                TransformerInfoSheet(
                    item: items[index],
                    binding: Binding(
                        get: { items[index] },
                        set: { newItem in
                            items[index] = newItem
                            transformers = items.map(\.value)
                        }
                    )
                )
            }
        case .catalog(let item):
            TransformerInfoSheet(item: item)
        }
    }
}

// MARK: - ActiveSheet

private extension TransformerListView {

    enum ActiveSheet: Identifiable {
        case applied(Int)
        case catalog(Item<any RunTransformer>)

        var id: String {
            switch self {
            case .applied(let index): return "applied-\(index)"
            case .catalog(let item): return "catalog-\(item.id.uuidString)"
            }
        }
    }
}
