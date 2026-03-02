import SwiftUI
import RunKit

/// A picker that reflects and controls the player's active interpolation strategy.
///
/// Reads the current selection via `@PlayerState` and writes back through
/// the same binding. Apply `.pickerStyle()` at the call-site to control
/// how it renders:
///
/// ```swift
/// InterpolationPicker()
///     .pickerStyle(.segmented)
/// ```
///
public struct InterpolationPicker: View {

    @PlayerState(\.interpolator)
    private var interpolator

    private static let catalog: [Item<any RunInterpolator>] = [
        Item(value: LinearRunInterpolator() as any RunInterpolator),
        Item(value: SmoothStepRunInterpolator() as any RunInterpolator),
        Item(value: CatmullRomRunInterpolator() as any RunInterpolator),
    ]

    public init() {}

    public var body: some View {
        Picker("Interpolation", selection: idBinding) {
            ForEach(Self.catalog) { item in
                Text(item.label).tag(item.id)
            }
        }
    }

    // MARK: - Private

    private var idBinding: Binding<UUID> {
        Binding(
            get: {
                Self.catalog.first { $0.value.label == interpolator.label }?.id
                    ?? Self.catalog[0].id
            },
            set: { id in
                if let item = Self.catalog.first(where: { $0.id == id }) {
                    interpolator = item.value
                }
            }
        )
    }
}
