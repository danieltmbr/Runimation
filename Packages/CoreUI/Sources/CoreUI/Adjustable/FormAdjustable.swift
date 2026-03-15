import SwiftUI

/// A type that can provide a SwiftUI form for editing its own properties.
///
/// Declare conformances in RunUI as extensions on RunKit (or other) types,
/// keeping data-layer packages free of UI dependencies.
///
/// ```swift
/// // In RunUI — extension on a RunKit type
/// extension WaveSamplingTransformer: FormAdjustable {
///     public func form(for binding: Binding<WaveSamplingTransformer>) -> some View {
///         WaveSamplingTransformerForm(value: binding)
///     }
/// }
/// ```
///
public protocol FormAdjustable {
    associatedtype Form: View
    @MainActor
    func form(for binding: Binding<Self>) -> Form
}
