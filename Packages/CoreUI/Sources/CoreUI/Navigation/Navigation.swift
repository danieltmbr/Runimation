import SwiftUI

/// A property wrapper that reads (and optionally writes) a value from a navigation scope
/// via the `NavigationModel` injected into the SwiftUI environment.
///
/// Use the read-only init for constants or `private(set)` properties:
/// ```swift
/// @Navigation(\.autoRestore) private var autoRestore
/// ```
///
/// Use the read-write init for mutable navigation state, which also exposes
/// a `Binding` via the `$` prefix:
/// ```swift
/// @Navigation(\.library.showLibrary) private var showLibrary
/// @Navigation(\.export.exportingRun) private var exportingRun
/// ```
///
@MainActor
@propertyWrapper
public struct Navigation<Value>: DynamicProperty {

    @Environment(NavigationModel.self)
    private var model

    private let get: @MainActor (NavigationModel) -> Value

    private let set: @MainActor (NavigationModel, Value) -> Void

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding {
            get(model)
        } set: { newValue in
            set(model, newValue)
        }
    }

    /// Read-only access. Use for `let` properties or computed values.
    public init(_ path: KeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    /// Read-write access. Use for `var` navigation properties.
    /// Exposes a `Binding` via `$`.
    public init(_ path: ReferenceWritableKeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
