import SwiftUI

/// A property wrapper that reads (and optionally writes) a value from the
/// `NavigationModel` injected into the SwiftUI environment.
///
/// Use the read-only init for `private(set)` properties:
/// ```swift
/// @NavigationState(\.autoRestore) private var autoRestore
/// ```
///
/// Use the read-write init for mutable navigation properties,
/// which also provides a `Binding` via the `$` prefix:
/// ```swift
/// @NavigationState(\.showLibrary) private var showLibrary
/// @NavigationState(\.statsPath) private var statsPath
/// ```
///
@MainActor
@propertyWrapper
struct NavigationState<Value>: DynamicProperty {

    @Environment(NavigationModel.self)
    private var model

    private let get: @MainActor (NavigationModel) -> Value

    private let set: @MainActor (NavigationModel, Value) -> Void

    var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    var projectedValue: Binding<Value> {
        Binding {
            get(model)
        } set: { newValue in
            set(model, newValue)
        }
    }

    /// Read-only access. Use for `let` or `private(set)` properties.
    init(_ path: KeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    /// Read-write access. Use for `var` navigation properties.
    /// Exposes a `Binding` via `$`.
    init(_ path: ReferenceWritableKeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
