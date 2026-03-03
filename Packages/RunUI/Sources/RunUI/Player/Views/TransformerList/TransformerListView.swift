import SwiftUI
import CoreUI
import RunKit

/// Displays the active transformer chain and the available catalog,
/// delegating list presentation and sheet management to `OptionList`.
///
/// This view is responsible only for what is transformer-specific:
/// syncing applied items with `RunPlayer.transformers` and providing
/// the catalog of available transformer instances.
///
public struct TransformerListView: View {

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
        OptionList(applied: appliedBinding, catalog: Self.catalog)
            .navigationTitle("Transformers")
            .onAppear { items = transformers.map { Item(value: $0) } }
    }

    // MARK: - Private

    private var appliedBinding: Binding<[Item<any RunTransformer>]> {
        Binding(
            get: { items },
            set: {
                items = $0
                transformers = $0.map(\.value)
            }
        )
    }
}
