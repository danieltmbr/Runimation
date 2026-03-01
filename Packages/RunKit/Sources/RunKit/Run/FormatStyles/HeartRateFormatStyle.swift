import Foundation

/// A `FormatStyle` that converts a heart rate value (BPM) into a
/// human-readable string in the form "72 bpm".
///
/// A value of zero signals missing sensor data and renders as "-- bpm".
///
public struct HeartRateFormatStyle: FormatStyle {
    public func format(_ value: Double) -> String {
        guard value > 0 else { return "-- bpm" }
        return "\(value.formatted(.number.precision(.fractionLength(0)))) bpm"
    }
}

public extension FormatStyle where Self == HeartRateFormatStyle {
    static var heartRate: HeartRateFormatStyle { .init() }
}
