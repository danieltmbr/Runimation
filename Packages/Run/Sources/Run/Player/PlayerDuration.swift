import Foundation

extension RunPlayer {
    
    /// Maps a run's actual recorded duration to a desired playback duration.
    ///
    /// A `Duration` is essentially a function `(runDuration) → playbackDuration`.
    /// Fixed presets ignore the run length and always produce the same playback time,
    /// while `.realTime` passes the recorded duration through unchanged.
    ///
    /// Use `callAsFunction(for:)` to resolve the playback duration for a given run:
    /// ```swift
    /// let playbackDuration = player.duration(for: run.duration)
    /// ```
    ///
    public struct Duration: Equatable, Hashable, Identifiable, Sendable {
        
        public var id: String { label }
        
        public let label: String
        
        private let duration: @Sendable (TimeInterval) -> TimeInterval
        
        private init(
            label: String,
            duration: @escaping @Sendable (TimeInterval) -> TimeInterval
        ) {
            self.label = label
            self.duration = duration
        }
        
        private init(
            label: String,
            duration: TimeInterval
        ) {
            self.label = label
            self.duration = { _ in duration }
        }
        
        /// Returns the playback duration for a run of the given recorded duration.
        ///
        public func callAsFunction(for value: TimeInterval) -> TimeInterval {
            duration(value)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        // MARK: - Predefined Durations
        
        /// Condenses the entire run into 15 seconds of playback.
        ///
        public static let fifteenSeconds = Self(label: "15s", duration: 15)

        /// Condenses the entire run into 30 seconds of playback.
        ///
        public static let thirtySeconds = Self(label: "30s", duration: 30)

        /// Condenses the entire run into 60 seconds of playback.
        ///
        public static let oneMinute = Self(label: "1 min", duration: 60)

        /// Plays the run at its actual recorded pace — a 45-minute run takes 45 minutes.
        /// 
        public static let realTime = Self(label: "Real-time") { $0 }
        
        public static var all: [Self] {
            [fifteenSeconds, thirtySeconds, oneMinute, realTime]
        }
    }
}
