import SwiftUI

/// A view that renders the configuration form for any `FormAdjustable` type.
///
/// Delegates entirely to `FormAdjustable.form(for:)`, keeping this view
/// free of any knowledge about the concrete type being configured.
///
/// ```swift
/// // Direct binding — no wrapper types involved
/// AdjustableForm(value: $warpConfig)
///
/// // Transformer case — caller constructs the typed binding
/// AdjustableForm(value: transformerBinding)
/// ```
///
public struct AdjustableForm: View {

    private let content: AnyView

    /// Creates an adjustable form for any `FormAdjustable` type.
    ///
    /// The generic parameter is resolved at the call site, allowing SE-0352
    /// to open existentials when needed. `AnyView` is stored once here so
    /// the struct itself carries no generic parameter.
    ///
    public init<T: FormAdjustable>(value: Binding<T>) {
        content = value.wrappedValue.form(for: value)
    }

    public var body: some View {
        content
    }
}
