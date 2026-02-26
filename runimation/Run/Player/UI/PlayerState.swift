import SwiftUI

/// A property wrapper that reads (and optionally writes) a value
/// from the `RunPlayer` injected into the SwiftUI environment.
///
/// Use the read-only init for `private(set)` properties:
/// ```swift
/// @PlayerState(\.isPlaying) private var isPlaying
/// @PlayerState(\.segments.animation) private var segment
/// ```
///
/// Use the read-write init for publicly settable properties,
/// which also provides a `Binding` via the `$` prefix:
/// ```swift
/// @PlayerState(\.duration) private var duration
/// @PlayerState(\.loop) private var loop
/// ```
///
@propertyWrapper
struct PlayerState<Value>: DynamicProperty {

    @Environment(RunPlayer.self)
    private var player

    private let get: (RunPlayer) -> Value
    
    private let set: (RunPlayer, Value) -> Void

    var wrappedValue: Value {
        get { get(player) }
        nonmutating set { set(player, newValue) }
    }

    var projectedValue: Binding<Value> {
        Binding {
            get(player)
        } set: { newValue in
            set(player, newValue)
        }
    }

    /// Read-only access. Use for `private(set)` properties
    /// such as `isPlaying`, `progress`, `runs`, `segments.*`.
    ///
    init(_ path: KeyPath<RunPlayer, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    /// Read-write access. Use for publicly settable properties
    /// such as `duration` and `loop`. Exposes a `Binding` via `$`.
    ///
    init(_ path: ReferenceWritableKeyPath<RunPlayer, Value>) {
        get = { $0[keyPath: path] }
        set = { player, value in player[keyPath: path] = value }
    }
}
