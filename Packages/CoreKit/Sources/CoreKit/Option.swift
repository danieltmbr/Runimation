import Foundation

/// A type that can describe itself with a human-readable label and description.
///
/// `RunTransformer` and `RunInterpolator` both inherit from this protocol,
/// so any processing strategy is self-describing.
///
public protocol Option {

    /// A short, human-readable name for this option.
    ///
    var label: String { get }

    /// A longer explanation of what this option does.
    ///
    var description: String { get }
}
