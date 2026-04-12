import RunKit
import SwiftUI

/// A property wrapper that reads (and optionally writes) a value
/// from the `RunLibrary` injected into the SwiftUI environment.
///
/// Use the read-only init for `private(set)` properties:
/// ```swift
/// @Library(\.isLoading) private var isLoading
/// @Library(\.isConnected) private var isConnected
/// ```
///
/// Use the read-write init for publicly settable properties,
/// which also provides a `Binding` via the `$` prefix.
///
@MainActor
@propertyWrapper
public struct Library<Value>: DynamicProperty {

    @Environment(RunLibrary.self)
    private var library

    private let get: @MainActor (RunLibrary) -> Value

    private let set: @MainActor (RunLibrary, Value) -> Void

    public var wrappedValue: Value {
        get { get(library) }
        nonmutating set { set(library, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding {
            get(library)
        } set: { newValue in
            set(library, newValue)
        }
    }

    /// Read-only access. Use for `private(set)` properties
    /// such as `isLoading`, `isConnected`.
    ///
    public init(_ path: KeyPath<RunLibrary, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    /// Read-write access. Use for publicly settable properties.
    /// Exposes a `Binding` via `$`.
    ///
    public init(_ path: ReferenceWritableKeyPath<RunLibrary, Value>) {
        get = { $0[keyPath: path] }
        set = { library, value in library[keyPath: path] = value }
    }
}
