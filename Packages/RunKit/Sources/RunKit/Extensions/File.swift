import Foundation

public extension Double {
    func clamped(_ minValue: Double, _ maxValue: Double) -> Double {
        min(max(self, minValue), maxValue)
    }
}
