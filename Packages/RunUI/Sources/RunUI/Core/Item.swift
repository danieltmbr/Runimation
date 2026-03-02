import Foundation
import RunKit

/// Wraps any value with a stable UUID for use in SwiftUI list operations
/// such as drag-to-reorder and swipe-to-delete.
///
/// The engine layer (`RunPlayer`) holds the pure protocol types; `Item` is a UI-only
/// concept that provides identity without leaking into the processing pipeline.
///
/// ```swift
/// let item = Item(value: GuassianRun() as any RunTransformer)
/// let updated = item.with(GuassianRun(configuration: .init(speed: 30)))
/// // updated.id == item.id — identity is preserved across configuration changes
/// ```
///
public struct Item<Value: Sendable>: Identifiable, Sendable, Option {

    public let id: UUID

    public let value: Value

    /// Forwarded from the wrapped value at construction time.
    ///
    public let label: String

    /// Forwarded from the wrapped value at construction time.
    ///
    public let description: String

    public init(id: UUID = UUID(), value: Value, label: String, description: String) {
        self.id = id
        self.value = value
        self.label = label
        self.description = description
    }

    /// Returns a copy with an updated value but the same identity.
    ///
    /// Use this when editing configuration (e.g. slider adjustments) so that
    /// SwiftUI preserves the row's position in an animated list.
    ///
    public func with(_ value: Value) -> Self {
        Self(id: id, value: value, label: label, description: description)
    }
}

// MARK: - Convenience for concrete Option-conforming types

extension Item where Value: Option {

    public init(value: Value) {
        self.init(value: value, label: value.label, description: value.description)
    }
}

// MARK: - Convenience for existential RunTransformer
//
// Swift does not allow `any RunTransformer` to satisfy `Value: Option` as a generic
// constraint, so a dedicated extension is needed for the existential type.

extension Item where Value == any RunTransformer {

    public init(value: any RunTransformer) {
        self.init(value: value, label: value.label, description: value.description)
    }
}

// MARK: - Convenience for existential RunInterpolator

extension Item where Value == any RunInterpolator {

    public init(value: any RunInterpolator) {
        self.init(value: value, label: value.label, description: value.description)
    }
}
