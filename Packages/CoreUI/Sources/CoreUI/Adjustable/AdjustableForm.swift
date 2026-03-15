import SwiftUI

/// A view that renders the configuration form for any `FormAdjustable` type.
///
/// Delegates entirely to `FormAdjustable.form(for:)`. SwiftUI receives a fully
/// typed view and can diff it correctly — no `AnyView` is involved here.
///
/// ```swift
/// AdjustableForm(value: $warpConfig)
/// AdjustableForm(value: transformerBinding)
/// ```
///
public struct AdjustableForm<T: FormAdjustable>: View {

    private let value: Binding<T>

    public init(value: Binding<T>) {
        self.value = value
    }

    public var body: some View {
        value.wrappedValue.form(for: value)
    }
}
