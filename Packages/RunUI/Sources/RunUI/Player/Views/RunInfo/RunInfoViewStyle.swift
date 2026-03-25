import SwiftUI

public struct RunInfoStyleConfiguration {
    
    let name: Text
    
    let date: Text
    
    let distance: Text
    
    let duration: Text
    
    init(
        name: Text,
        date: Text,
        distance: Text,
        duration: Text
    ) {
        self.name = name
        self.date = date
        self.distance = distance
        self.duration = duration
    }
}


public protocol RunInfoViewStyle: Sendable {
    typealias Configuration = RunInfoStyleConfiguration
    
    associatedtype Body: View
    
    @MainActor @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
}

// MARK: - Built-in styles

public extension RunInfoViewStyle where Self == RegularRunInfoViewStyle {
    static var `default`: RegularRunInfoViewStyle { RegularRunInfoViewStyle() }
}

public extension RunInfoViewStyle where Self == CompactRunInfoViewStyle {
    static var compact: CompactRunInfoViewStyle { CompactRunInfoViewStyle() }
}
