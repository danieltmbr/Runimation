import Foundation

/// Pairs a display name with a `RunInterpolator` implementation,
/// making interpolation strategies selectable in the UI.
///
/// Equality and hashing are based solely on `id` (the display name),
/// since `any RunInterpolator` protocol values are not directly comparable.
///
struct RunInterpolatorOption: Identifiable, Equatable, Hashable {

    let id: String

    var label: String { id }

    let interpolator: any RunInterpolator

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension RunInterpolatorOption {

    /// Linearly blends metric values between surrounding GPS data points.
    ///
    static let linear = Self(id: "Linear", interpolator: LinearRunInterpolator())

    /// Blends metric values with a smooth-step (ease-in/ease-out) curve
    /// between surrounding GPS data points.
    ///
    static let smoothStep = Self(id: "Smooth Step", interpolator: SmoothStepRunInterpolator())

    /// Fits a Catmull-Rom spline through the original GPS data points,
    /// producing C¹-continuous curves that pass through every sample.
    ///
    static let catmullRom = Self(id: "Catmull-Rom", interpolator: CatmullRomRunInterpolator())

    /// All built-in interpolation options, in display order.
    ///
    static var all: [Self] { [linear, smoothStep, catmullRom] }
}
