import SwiftUI
import CoreUI
import RunKit

/// A row that shows the active interpolation strategy and navigates to
/// `InterpolationList` for selection.
///
/// Place inside a `NavigationStack` (provided by `CustomisationPanel`).
///
public struct InterpolationPicker: View {

    @PlayerState(\.interpolator)
    private var interpolator

    public init() {}

    public var body: some View {
        NavigationLink {
            InterpolationList()
        } label: {
            LabeledContent("Interpolation", value: interpolator.label)
        }
    }
}

// MARK: - Selection List

/// Full-screen list of available interpolation strategies.
///
/// Displays name and description for each entry. Tapping an item selects it
/// and dismisses the view back to the panel.
///
public struct InterpolationList: View {

    @PlayerState(\.interpolator)
    private var interpolator

    private static let catalog: [Item<any RunInterpolator>] = [
        Item(value: LinearRunInterpolator() as any RunInterpolator),
        Item(value: SmoothStepRunInterpolator() as any RunInterpolator),
        Item(value: CatmullRomRunInterpolator() as any RunInterpolator),
    ]

    public init() {}

    public var body: some View {
        SelectionList(
            items: Self.catalog,
            selection: Binding(
                get: { Self.catalog.first { $0.value.label == interpolator.label } ?? Self.catalog[0] },
                set: { interpolator = $0.value }
            )
        )
        .navigationTitle("Interpolation")
    }
}
