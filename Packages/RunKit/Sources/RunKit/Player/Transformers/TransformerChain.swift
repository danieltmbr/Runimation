import Foundation

/// Composes multiple `RunTransformer`s into a single sequential pipeline.
///
/// Transformers are applied left to right: the output of each becomes the
/// input of the next. The chain itself conforms to `RunTransformer`, so it
/// can be nested or passed anywhere a single transformer is expected.
///
/// ```swift
/// let chain = TransformerChain(transformers: [
///     NormalisedRun(),
///     GaussianRun(sigma: 2),
/// ])
/// let processed = run.transform(by: chain)
/// ```
///
public struct TransformerChain: RunTransformer {
    
    private let transformers: [RunTransformer]
    
    init(transformers: [RunTransformer]) {
        self.transformers = transformers
    }
    
    public func transform(_ run: Run) -> Run {
        transformers.reduce(run) { run, transformer in
            transformer.transform(run)
        }
    }
    
    func append(transformer: some RunTransformer) -> Self {
        Self(transformers: self.transformers + [transformer])
    }
}
