import Foundation

/// A `FormatStyle` that converts a negated pace value (stored as `-(min/km)`) into
/// a human-readable "M:SS" string.
///
/// Pace values are stored negated so that faster pace plots *higher* on a chart
/// with a standard ascending Y axis. This formatter reverses the negation before
/// producing the label.
///
public struct PaceFormatStyle: FormatStyle {
    public func format(_ value: Double) -> String {
        let totalSeconds = Int(-value * 60)
        guard totalSeconds > 0 else { return "--:--" }
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

public extension FormatStyle where Self == PaceFormatStyle {
    static var pace: PaceFormatStyle { .init() }
}
