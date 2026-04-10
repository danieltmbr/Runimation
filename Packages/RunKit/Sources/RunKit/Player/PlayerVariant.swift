extension RunPlayer {

    /// Identifies a reading variant by its semantic purpose and sampling rate.
    ///
    /// Used with `@dynamicMemberLookup` on `Runs`, `Segments`, and `ProgressValues`
    /// to enable keypath-based access such as `\.run.animation` or `\.progress.metrics`.
    ///
    public struct Variant: Sendable {

        public enum Purpose: Equatable, Sendable {
            /// Reads the normalised run — use to drive animations.
            case animation
            /// Reads the transformed run — use for diagnostics.
            case diagnostics
            /// Reads the original run — use for accurate metrics.
            case metrics
        }

        public let purpose: Purpose
        public let fps: Int

        public static let animation   = Variant(purpose: .animation,   fps: 30)
        public static let metrics     = Variant(purpose: .metrics,     fps: 24)
        public static let diagnostics = Variant(purpose: .diagnostics, fps: 24)
    }
}
