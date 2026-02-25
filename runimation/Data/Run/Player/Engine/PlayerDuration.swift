import Foundation

extension RunPlayer {
    
    struct Duration: Equatable, Identifiable, Sendable {
        
        var id: String { label }
        
        let label: String
        
        private let duration: (TimeInterval) -> TimeInterval
        
        private init(
            label: String,
            duration: @escaping (TimeInterval) -> TimeInterval
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
        
        func callAsFunction(for value: TimeInterval) -> TimeInterval {
            duration(value)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        static let fifteenSeconds = Self(label: "15s", duration: 15)
        
        static let thirtySeconds = Self(label: "30s", duration: 30)
        
        static let oneMinute = Self(label: "1 min", duration: 60)
        
        static let realTime = Self(label: "Real-time") { $0 }
        
        static var all: [Self] {
            [fifteenSeconds, thirtySeconds, oneMinute, realTime]
        }
    }
}
