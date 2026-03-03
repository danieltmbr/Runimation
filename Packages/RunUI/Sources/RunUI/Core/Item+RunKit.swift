import CoreUI
import RunKit

// MARK: - Convenience for existential RunTransformer
//
// Swift does not allow `any RunTransformer` to satisfy `Value: Option` as a generic
// constraint, so a dedicated extension is needed for the existential type.

extension Item where Value == any RunTransformer {

    public init(value: any RunTransformer) {
        self.init(value: value, label: value.label, description: value.description)
    }
}

// MARK: - Convenience for existential RunInterpolator

extension Item where Value == any RunInterpolator {

    public init(value: any RunInterpolator) {
        self.init(value: value, label: value.label, description: value.description)
    }
}
