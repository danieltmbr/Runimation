import Foundation

/// A `FormatStyle` that converts a `TimeInterval` (seconds) into a
/// human-readable duration string.
///
/// Durations under one hour render as "M:SS"; one hour or longer render
/// as "H:MM:SS". Uses `Duration.TimeFormatStyle` internally.
///
public struct DurationFormatStyle: FormatStyle {
    public func format(_ value: TimeInterval) -> String {
        let duration = Duration.seconds(value)
        if value >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 1)))
        } else {
            return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
        }
    }
}

public extension FormatStyle where Self == DurationFormatStyle {
    static var runDuration: DurationFormatStyle { .init() }
}
