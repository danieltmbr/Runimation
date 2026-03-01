import Foundation

/// Run Transformer transforms the data of a run depending
/// on its internal implementation while keeping the strucutre
/// of the data untouched.
///
/// For example it can return a run where the metrics are
/// normalised to [0, 1] or [-1, 1] ranges.
///
public protocol RunTransformer: Sendable {

    func transform(_ run: Run) -> Run
}

extension Run {
    func transform(by transformer: RunTransformer) -> Run {
        transformer.transform(self)
    }
}
