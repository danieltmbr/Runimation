import SwiftUI

/// A reusable list for any ordered, multi-select `Option` chain.
///
/// Presents two sections — **Applied** (reorderable, deletable, editable) and
/// **Available** (catalog, add-only) — and opens an `OptionDetail` sheet on the
/// info button of any row.
///
/// ```swift
/// OptionList(applied: $items, catalog: Self.catalog)
///     .navigationTitle("Transformers")
/// ```
///
public struct OptionList<Value: Sendable>: View {

    @Binding
    var applied: [Item<Value>]

    let catalog: [Item<Value>]

    @State
    private var activeSheet: ActiveSheet? = nil

    public init(applied: Binding<[Item<Value>]>, catalog: [Item<Value>] = []) {
        self._applied = applied
        self.catalog = catalog
    }

    public var body: some View {
        Form {
            appliedSection
            catalogSection
        }
        .formStyle(.grouped)
        #if os(iOS)
        .environment(\.editMode, .constant(.active))
        #endif
        .sheet(item: $activeSheet) { sheetContent(for: $0) }
    }

    // MARK: - Sections

    private var appliedSection: some View {
        Section("Applied") {
            if applied.isEmpty {
                Text("None applied")
                    .foregroundStyle(.secondary)
                    .deleteDisabled(true)
                    .moveDisabled(true)
            }
            ForEach(Array(applied.enumerated()), id: \.element.id) { index, item in
                appliedRow(item: item, index: index)
            }
            .onMove { from, to in applied.move(fromOffsets: from, toOffset: to) }
            .onDelete { offsets in applied.remove(atOffsets: offsets) }
        }
    }

    private var catalogSection: some View {
        Section("Available") {
            ForEach(catalog) { item in
                catalogRow(item: item)
            }
            .moveDisabled(true)
            .deleteDisabled(true)
        }
    }

    // MARK: - Rows

    private func appliedRow(item: Item<Value>, index: Int) -> some View {
        HStack {
            Text(item.label)
            Spacer()
            Button { activeSheet = .applied(index) } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
        }
    }

    private func catalogRow(item: Item<Value>) -> some View {
        HStack {
            Text(item.label)
            Spacer()
            Button { activeSheet = .catalog(item) } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            Button {
                applied.append(Item(value: item.value, label: item.label, description: item.description))
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Sheet

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .applied(let index) where index < applied.count:
            OptionDetail(
                item: applied[index],
                binding: Binding(
                    get: { applied[index] },
                    set: { applied[index] = $0 }
                )
            )
        case .catalog(let item):
            OptionDetail(item: item)
        default:
            EmptyView()
        }
    }
}

// MARK: - ActiveSheet

private extension OptionList {

    enum ActiveSheet: Identifiable {
        case applied(Int)
        case catalog(Item<Value>)

        var id: String {
            switch self {
            case .applied(let index): return "applied-\(index)"
            case .catalog(let item): return "catalog-\(item.id.uuidString)"
            }
        }
    }
}
