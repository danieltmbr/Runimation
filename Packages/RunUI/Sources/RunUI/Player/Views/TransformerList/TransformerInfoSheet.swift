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
/// TransformerInfoSheet(option: option, binding: $selectedTransformers[index])
///
/// // Read-only (Catalog)
/// TransformerInfoSheet(option: option)
/// ```
///
public struct TransformerInfoSheet: View {

    let option: RunTransformerOption

    var binding: Binding<RunTransformerOption>? = nil

    @State
    private var targetCount: Int
    
    @State
    private var rank: Int

    public init(option: RunTransformerOption, binding: Binding<RunTransformerOption>? = nil) {
        self.option = option
        self.binding = binding
        let ws = option.transformer as? WaveSamplingTransformer
        _targetCount = State(initialValue: ws?.targetCount ?? 15)
        _rank = State(initialValue: ws?.rank ?? 5)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(option.description)
                        .foregroundStyle(.secondary)
                }

                if binding != nil, option.transformer is WaveSamplingTransformer {
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
            .navigationTitle(option.label)
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
                binding?.wrappedValue = option.with(WaveSamplingTransformer(targetCount: targetCount, rank: rank))
            }
        )
    }

    private var rankBinding: Binding<Double> {
        Binding(
            get: { Double(rank) },
            set: { newValue in
                rank = Int(newValue)
                binding?.wrappedValue = option.with(WaveSamplingTransformer(targetCount: targetCount, rank: rank))
            }
        )
    }
}
