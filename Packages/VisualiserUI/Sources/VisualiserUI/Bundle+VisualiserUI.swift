import Foundation

/// Exposes the VisualiserUI package bundle so other targets (e.g. the RuniDemos app)
/// can reference shaders and resources compiled into this package.
public extension Bundle {
    static let visualiserUI: Bundle = .module
}
