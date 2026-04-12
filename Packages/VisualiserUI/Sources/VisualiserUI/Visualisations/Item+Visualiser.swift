import CoreUI

// MARK: - Convenience for existential Visualisation
//
// Swift does not allow `any Visualisation` to satisfy `Value: Option` as a generic
// constraint, so a dedicated extension is needed for the existential type.

extension Item where Value == any Visualisation {

    public init(value: any Visualisation) {
        self.init(value: value, label: value.label, description: value.description)
    }
}
