import Foundation

/// All run-derived values the animation shader needs each frame.
///
/// Construct from `RunPlayer` state in the app layer and pass to `WarpView`.
/// Keeps the Animations package independent of RunKit.
///
public struct AnimationState: Sendable {

    /// Pace-weighted animation clock (seconds).
    public var time: Float

    /// Normalised running speed (0–1).
    public var speed: Float

    /// Normalised heart rate (0–1).
    public var heartRate: Float

    /// Normalised elevation (0–1).
    public var elevation: Float

    /// Speed-weighted heading unit vector.
    public var direction: SIMD2<Float>

    public static let zero = AnimationState(
        time: 0, speed: 0, heartRate: 0, elevation: 0, direction: .zero
    )

    public init(
        time: Float,
        speed: Float,
        heartRate: Float,
        elevation: Float,
        direction: SIMD2<Float>
    ) {
        self.time = time
        self.speed = speed
        self.heartRate = heartRate
        self.elevation = elevation
        self.direction = direction
    }
}
