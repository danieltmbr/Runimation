import Foundation

/// A `FormatStyle` that converts a distance value (meters) into a
/// human-readable string in the form "10.52 km".
///
public struct DistanceFormatStyle: FormatStyle {
    public func format(_ value: Double) -> String {
        let km = value / 1000.0
        return "\(km.formatted(.number.precision(.fractionLength(2)))) km"
    }
}

public extension FormatStyle where Self == DistanceFormatStyle {
    static var distance: DistanceFormatStyle { .init() }
}
