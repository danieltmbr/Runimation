import Foundation

/// All run-derived values the animation shader needs each frame.
///
/// Construct from `RunPlayer` state in the app layer and pass to `WarpView`.
/// Keeps the Animations package independent of RunKit.
///
public struct AnimationState: Sendable {
    
    /// Normalised coordinates (-1, 1)
    ///
    public var coordinates: SIMD2<Float>

    /// Normalised heading unit vector (-1, 1).
    ///
    public var direction: SIMD2<Float>
    
    /// Normalised elevation (0, 1).
    ///
    public var elevation: Float
    
    /// Normalised heart rate (0, 1).
    ///
    public var heartRate: Float
    
    /// A list of normalised coordinates,
    /// representing the full path of the run.  (-1, 1).
    ///
    public var path: [SIMD2<Float>]
    
    /// Normalised running speed (0, 1).
    ///
    public var speed: Float
    
    /// Pace-weighted animation clock (seconds).
    ///
    public var time: Float

    public static let zero = AnimationState(
        coordinates: SIMD2<Float>(0, 0),
        direction: .zero,
        elevation: 0,
        heartRate: 0,
        path: [],
        speed: 0,
        time: 0
    )
    
    public init(
        coordinates: SIMD2<Float>,
        direction: SIMD2<Float>,
        elevation: Float,
        heartRate: Float,
        path: [SIMD2<Float>],
        speed: Float,
        time: Float
    ) {
        self.coordinates = coordinates
        self.direction = direction
        self.elevation = elevation
        self.heartRate = heartRate
        self.path = path
        self.speed = speed
        self.time = time
    }
}
