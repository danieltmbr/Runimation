import Foundation

struct TransformerChain: RunTransformer {
    
    private let transformers: [RunTransformer]
    
    init(transformers: [RunTransformer]) {
        self.transformers = transformers
    }
    
    func transform(_ run: Run) -> Run {
        transformers.reduce(run) { run, transformer in
            transformer.transform(run)
        }
    }
    
    func append(transformer: some RunTransformer) -> Self {
        Self(transformers: self.transformers + [transformer])
    }
}
