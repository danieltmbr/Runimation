import Foundation

/// A `FormatStyle` that converts a cadence value (steps per minute) into a
/// human-readable string in the form "172 spm".
///
/// A value of zero signals missing sensor data and renders as "-- spm".
///
public struct CadenceFormatStyle: FormatStyle {
    public func format(_ value: Double) -> String {
        guard value > 0 else { return "-- spm" }
        return "\(value.formatted(.number.precision(.fractionLength(0)))) spm"
    }
}

public extension FormatStyle where Self == CadenceFormatStyle {
    static var cadence: CadenceFormatStyle { .init() }
}
