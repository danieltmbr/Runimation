import SwiftUI

/// Per-window observable navigation registry.
///
/// `NavigationModel` is an extensible container for feature-specific navigation scopes.
/// Each feature defines its own `@Observable` scope class and registers it at window
/// creation time. The scope is then reachable via a `NavigationModel` extension computed
/// property and the `@Navigation` property wrapper.
///
/// ## Registering a scope
/// ```swift
/// let navigation = NavigationModel(autoRestore: true)
/// navigation.register(ExportNavigation())
/// ```
///
/// ## Extending the model (in the feature's module)
/// ```swift
/// extension NavigationModel {
///     var export: ExportNavigation {
///         get { scope(ExportNavigation.self) }
///         set { }  // no-op; required for ReferenceWritableKeyPath composition
///     }
/// }
/// ```
///
/// ## Observation
/// The internal scope dictionary is `@ObservationIgnored`. SwiftUI only tracks accesses
/// to properties on the returned scope objects, preserving fine-grained observation. ✓
///
@MainActor
@Observable
public final class NavigationModel: Equatable {

    public nonisolated static func == (lhs: NavigationModel, rhs: NavigationModel) -> Bool { lhs === rhs }

    // MARK: - Base Config

    /// Whether this window restores its last session on launch.
    ///
    public let autoRestore: Bool

    // MARK: - Scope Registry

    /// Scope objects keyed by their metatype identity.
    /// `@ObservationIgnored` so that dictionary lookups don't pollute observation tracking.
    ///
    @ObservationIgnored
    private var _scopes: [ObjectIdentifier: AnyObject] = [:]

    // MARK: - Init

    public init(autoRestore: Bool) {
        self.autoRestore = autoRestore
    }

    // MARK: - Registration

    /// Registers a navigation scope so it can be reached via a `NavigationModel` extension.
    ///
    /// Call once per scope at window creation time, before the view hierarchy is built.
    ///
    public func register<S: AnyObject>(_ scope: S) {
        _scopes[ObjectIdentifier(S.self)] = scope
    }

    // MARK: - Retrieval

    /// Returns the registered scope of the given type.
    ///
    /// Crashes with a descriptive message if the scope was not registered.
    /// This is called by `NavigationModel` extensions defined in feature modules.
    /// Prefer using `@Navigation` keypaths over calling this directly.
    ///
    public func scope<S: AnyObject>(_ type: S.Type) -> S {
        guard let scope = _scopes[ObjectIdentifier(type)] as? S else {
            fatalError(
                """
                Navigation scope '\(S.self)' has not been registered. \
                Call navigationModel.register(\(S.self)()) before building the view hierarchy.
                """
            )
        }
        return scope
    }
}
