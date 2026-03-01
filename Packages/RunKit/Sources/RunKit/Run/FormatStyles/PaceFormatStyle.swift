import Foundation

/// A `FormatStyle` that converts a running speed (m/s) into a human-readable
/// pace string in the form "M:SS /km".
///
/// Speeds below 0.3 m/s (a near-standstill) are treated as missing data and
/// render as "--:-- /km".
///
public struct PaceFormatStyle: FormatStyle {
    public func format(_ value: Double) -> String {
        guard value >= 0.3 else { return "--:-- /km" }
        let secsPerKm = Int(1000.0 / value)
        return String(format: "%d:%02d /km", secsPerKm / 60, secsPerKm % 60)
    }
}

public extension FormatStyle where Self == PaceFormatStyle {
    static var pace: PaceFormatStyle { .init() }
}
