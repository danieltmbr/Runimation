import Foundation

extension RunPlayer {
    
    /// Timing couples the two values an interpolator needs
    /// to compute the appropriate frame density for a run.
    ///
    struct Timing: Equatable, Sendable {
        
        /// Target playback duration in seconds.
        ///
        let duration: TimeInterval
        
        /// Target frames per second.
        ///
        let fps: Double
    }
}
