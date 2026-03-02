import SwiftUI
import RunKit

/// Displays a transformer's label and description, with optional editable
/// configuration controls when a writable binding is provided.
///
/// Pass a `binding` to enable editing (used for Applied transformers).
/// Omit it for a read-only view (used for catalog entries).
///
/// ```swift
/// // Editable (Applied)
/// TransformerInfoSheet(item: item, binding: $items[index])
///
/// // Read-only (Catalog)
/// TransformerInfoSheet(item: item)
/// ```
///
public struct TransformerInfoSheet: View {

    let item: Item<any RunTransformer>

    var binding: Binding<Item<any RunTransformer>>? = nil

    @State
    private var targetCount: Int

    @State
    private var rank: Int

    public init(item: Item<any RunTransformer>, binding: Binding<Item<any RunTransformer>>? = nil) {
        self.item = item
        self.binding = binding
        let ws = item.value as? WaveSamplingTransformer
        _targetCount = State(initialValue: ws?.targetCount ?? 15)
        _rank = State(initialValue: ws?.rank ?? 5)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.description)
                        .foregroundStyle(.secondary)
                }

                if binding != nil, item.value is WaveSamplingTransformer {
                    Section("Configuration") {
                        LabeledContent("Target Count: \(targetCount)") {
                            Slider(value: targetCountBinding, in: 5...100, step: 1)
                        }
                        LabeledContent("Rank: \(rank)") {
                            Slider(value: rankBinding, in: 1...10, step: 1)
                        }
                    }
                }
            }
            .navigationTitle(item.label)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .presentationDetents([.medium])
    }

    // MARK: - Private

    private var targetCountBinding: Binding<Double> {
        Binding(
            get: { Double(targetCount) },
            set: { newValue in
                targetCount = Int(newValue)
                binding?.wrappedValue = item.with(WaveSamplingTransformer(targetCount: targetCount, rank: rank))
            }
        )
    }

    private var rankBinding: Binding<Double> {
        Binding(
            get: { Double(rank) },
            set: { newValue in
                rank = Int(newValue)
                binding?.wrappedValue = item.with(WaveSamplingTransformer(targetCount: targetCount, rank: rank))
            }
        )
    }
}
