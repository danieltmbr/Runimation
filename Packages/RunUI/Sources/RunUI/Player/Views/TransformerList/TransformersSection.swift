import SwiftUI
import CoreUI
import RunKit

/// Two Form sections for managing the transformer pipeline, intended to be placed
/// directly inside a parent `Form`.
///
/// - **Pre-processing** — the active transformer chain. Each row is a `DisclosureGroup`
///   that expands inline to show its configuration form and description.
///   Rows are swipe-to-delete on iOS and right-click deletable on macOS.
/// - **Add** — catalog of available transformers, each with a `+` button to append
///   to the active chain.
///
/// Requires `RunPlayer` in the environment via `.player(_:)`.
///
public struct TransformersSection: View {

    @PlayerState(\.transformers)
    private var transformers

    @State
    private var items: [Item<any RunTransformer>] = []

    private static let catalog: [Item<any RunTransformer>] = [
        Item(value: GuassianRun() as any RunTransformer),
        Item(value: SpeedWeightedRun() as any RunTransformer),
        Item(value: WaveSamplingTransformer() as any RunTransformer),
    ]

    public init() {}

    public var body: some View {
        Group {
            appliedSection
            catalogSection
        }
        .onAppear { items = transformers.map { Item(value: $0) } }
    }

    // MARK: - Applied Section

    private var appliedSection: some View {
        Section("Pre-processing") {
            if items.isEmpty {
                Text("None")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    expandableRow(for: item)
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)
                    transformers = items.map(\.value)
                }
            }
        }
    }

    // MARK: - Catalog Section

    private var catalogSection: some View {
        Section("Add") {
            ForEach(Self.catalog) { catalogItem in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(catalogItem.label)
                        Text(catalogItem.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        items.append(Item(value: catalogItem.value))
                        transformers = items.map(\.value)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Expandable Row

    private func expandableRow(for item: Item<any RunTransformer>) -> some View {
        DisclosureGroup {
            if let adjustable = item.value as? any FormAdjustable,
               let index = items.firstIndex(where: { $0.id == item.id }) {
                adjustableForm(for: adjustable, at: index)
            }
            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Text(item.label)
        }
    }

    // MARK: - Form Bridge

    /// SE-0352 opens `any FormAdjustable` to a concrete `T`, bridging the items-array
    /// slot to the typed `Binding<T>` that `AdjustableForm` requires.
    /// The force-cast in the getter is safe because `T` was retrieved from the same value.
    ///
    private func adjustableForm<T: FormAdjustable>(for value: T, at index: Int) -> AnyView {
        AnyView(AdjustableForm(value: Binding<T>(
            get: { items[index].value as! T },
            set: { newValue in
                items[index] = items[index].with(newValue as! any RunTransformer)
                transformers = items.map(\.value)
            }
        )))
    }
}
