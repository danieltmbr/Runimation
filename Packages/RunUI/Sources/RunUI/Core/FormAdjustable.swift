import SwiftUI

/// A type that can provide a SwiftUI form for editing its own properties.
///
/// Declare conformances in RunUI as extensions on RunKit (or other) types,
/// keeping data-layer packages free of UI dependencies.
///
/// ```swift
/// // In RunUI — extension on a RunKit type
/// extension WaveSamplingTransformer: FormAdjustable {
///     public func form(for binding: Binding<WaveSamplingTransformer>) -> AnyView {
///         AnyView(WaveSamplingTransformerForm(value: binding))
///     }
/// }
/// ```
///
/// - Note: `form(for:)` returns `AnyView` to support calling through
///   `any FormAdjustable` existentials — the same technique SwiftUI uses
///   internally for style protocols such as `ButtonStyle`.
///
public protocol FormAdjustable {
    @MainActor
    func form(for binding: Binding<Self>) -> AnyView
}
