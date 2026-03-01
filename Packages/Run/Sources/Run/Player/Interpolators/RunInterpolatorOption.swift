import Foundation

/// Pairs a display name with a `RunInterpolator` implementation,
/// making interpolation strategies selectable in the UI.
///
/// Equality and hashing are based solely on `id` (the display name),
/// since `any RunInterpolator` protocol values are not directly comparable.
///
public struct RunInterpolatorOption: Identifiable, Equatable, Hashable, Sendable {

    public var id: String { label }

    public let label: String

    let interpolator: any RunInterpolator

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension RunInterpolatorOption {

    /// Linearly blends metric values between surrounding GPS data points.
    ///
    public static let linear = Self(label: "Linear", interpolator: LinearRunInterpolator())

    /// Blends metric values with a smooth-step (ease-in/ease-out) curve
    /// between surrounding GPS data points.
    ///
    public static let smoothStep = Self(label: "Smooth Step", interpolator: SmoothStepRunInterpolator())

    /// Fits a Catmull-Rom spline through the original GPS data points,
    /// producing C¹-continuous curves that pass through every sample.
    ///
    public static let catmullRom = Self(label: "Catmull-Rom", interpolator: CatmullRomRunInterpolator())

    /// All built-in interpolation options, in display order.
    ///
    public static var all: [Self] { [linear, smoothStep, catmullRom] }
}
