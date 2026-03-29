import Foundation

/// Maps between normalised slider positions [0, 1] and playback durations.
///
/// For short runs (≤ `linearCap`) the full slider range maps linearly from
/// `minimumDuration` to `runDuration`.
///
/// For longer runs the slider is split into two sections:
/// - 0 … `linearFraction`: linearly covers `minimumDuration` … `linearCap`
///   (tick marks fall at 15 s, 30 s, and 60 s within this section)
/// - `linearFraction` … 1: exponentially covers `linearCap` … `runDuration`,
///   giving finer control at shorter durations and a long tail toward real-time.
///
public struct PlaybackDurationMapping: Equatable, Sendable {

    // MARK: - Constants

    /// Shortest selectable playback duration.
    ///
    public static let minimumDuration: TimeInterval = 5

    /// The maximum duration of the linear slider section.
    ///
    public static let linearCap: TimeInterval = 60

    /// The fraction of the slider width reserved for the linear section.
    ///
    public static let linearFraction: Double = 0.6

    /// Standard duration presets used for tick mark placement.
    ///
    public static let standardPresets: [TimeInterval] = [15, 30, 60]

    // MARK: - Properties

    /// The actual recorded duration of the run, used as the slider's maximum.
    ///
    public let runDuration: TimeInterval

    // MARK: - Init

    public init(runDuration: TimeInterval) {
        self.runDuration = max(runDuration, Self.minimumDuration)
    }

    // MARK: - Mapping

    /// Converts a normalised slider position [0, 1] to playback seconds.
    ///
    public func seconds(at position: Double) -> TimeInterval {
        let p = position.clamped(0, 1)
        if isShortRun {
            return Self.minimumDuration + p * (runDuration - Self.minimumDuration)
        }
        if p <= Self.linearFraction {
            let t = p / Self.linearFraction
            return Self.minimumDuration + t * (Self.linearCap - Self.minimumDuration)
        }
        let t = (p - Self.linearFraction) / (1 - Self.linearFraction)
        return Self.linearCap * pow(runDuration / Self.linearCap, t)
    }

    /// Converts playback seconds to a normalised slider position [0, 1].
    ///
    public func position(for seconds: TimeInterval) -> Double {
        let s = seconds.clamped(Self.minimumDuration, runDuration)
        if isShortRun {
            guard runDuration > Self.minimumDuration else { return 0 }
            return (s - Self.minimumDuration) / (runDuration - Self.minimumDuration)
        }
        if s <= Self.linearCap {
            let t = (s - Self.minimumDuration) / (Self.linearCap - Self.minimumDuration)
            return t * Self.linearFraction
        }
        let t = log(s / Self.linearCap) / log(runDuration / Self.linearCap)
        return Self.linearFraction + t * (1 - Self.linearFraction)
    }

    /// Normalised positions for the standard presets that fall strictly within
    /// [`minimumDuration`, `runDuration`). Position 1.0 (real-time) is intentionally
    /// excluded so callers can append it separately with a distinct "Real" label.
    ///
    public var tickPositions: [Double] {
        Self.standardPresets
            .filter { $0 >= Self.minimumDuration && $0 < runDuration }
            .map { position(for: $0) }
    }

    // MARK: - Private

    private var isShortRun: Bool {
        runDuration <= Self.linearCap
    }
}
