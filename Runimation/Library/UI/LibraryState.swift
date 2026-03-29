import SwiftUI

/// A property wrapper that reads (and optionally writes) a value
/// from the `RunLibrary` injected into the SwiftUI environment.
///
/// Use the read-only init for `private(set)` properties:
/// ```swift
/// @LibraryState(\.entries) private var entries
/// @LibraryState(\.isLoading) private var isLoading
/// ```
///
/// Use the read-write init for publicly settable properties,
/// which also provides a `Binding` via the `$` prefix.
///
@MainActor
@propertyWrapper
struct LibraryState<Value>: DynamicProperty {

    @Environment(RunLibrary.self)
    private var library

    private let get: @MainActor (RunLibrary) -> Value
    
    private let set: @MainActor (RunLibrary, Value) -> Void

    var wrappedValue: Value {
        get { get(library) }
        nonmutating set { set(library, newValue) }
    }

    var projectedValue: Binding<Value> {
        Binding {
            get(library)
        } set: { newValue in
            set(library, newValue)
        }
    }

    /// Read-only access. Use for `private(set)` properties
    /// such as `entries`, `isLoading`, `hasReachedEnd`.
    ///
    init(_ path: KeyPath<RunLibrary, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    /// Read-write access. Use for publicly settable properties.
    /// Exposes a `Binding` via `$`.
    ///
    init(_ path: ReferenceWritableKeyPath<RunLibrary, Value>) {
        get = { $0[keyPath: path] }
        set = { library, value in library[keyPath: path] = value }
    }
}
