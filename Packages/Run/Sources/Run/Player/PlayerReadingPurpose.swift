import Foundation

extension RunPlayer {
    
    /// Reading purpose indicates the player how the data
    /// is inteded to use so it can provide the most suitable
    /// one to a given request.
    ///
    public enum ReadingPurpose: Equatable, Sendable {
        
        /// Reads values from the original run to provide
        /// the most accurate data to the consumer.
        ///
        case metrics
        
        /// Reads values from the transformed run to
        /// provide an insight of how the data will be used.
        ///
        case diagnostics
        
        /// Reads values from the normalised run that
        /// can be leveraged to drive animations.
        ///
        case animation
    }
}
