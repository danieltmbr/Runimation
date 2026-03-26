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

    @Environment(\.dismiss)
    private var dismiss

    public init() {}

    public var body: some View {
        List(Self.catalog) { item in
            let isSelected = item.value.label == interpolator.label
            Button {
                interpolator = item.value
                dismiss()
            } label: {
                LabeledContent {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                        Text(item.value.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle("Interpolation")
    }
}
