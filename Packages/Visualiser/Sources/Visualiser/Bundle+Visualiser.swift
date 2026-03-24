import Foundation

/// Exposes the Visualiser package bundle so other targets (e.g. the RuniDemos app)
/// can reference shaders and resources compiled into this package.
public extension Bundle {
    static let visualiser: Bundle = .module
}
