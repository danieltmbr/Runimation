import Foundation

/// A `FormatStyle` that converts an elevation value (meters) into a
/// human-readable string in the form "342 m".
///
public struct ElevationFormatStyle: FormatStyle {
    public func format(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0)))) m"
    }
}

public extension FormatStyle where Self == ElevationFormatStyle {
    static var elevation: ElevationFormatStyle { .init() }
}
