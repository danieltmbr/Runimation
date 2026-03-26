import SwiftUI

public struct RunInfoStyleConfiguration {
    
    let alignment: HorizontalAlignment
        
    let date: Text
    
    let distance: Text
    
    let duration: Text
    
    let name: Text
    
    init(
        alignment: HorizontalAlignment,
        date: Text,
        distance: Text,
        duration: Text,
        name: Text
    ) {
        self.alignment = alignment
        self.date = date
        self.distance = distance
        self.duration = duration
        self.name = name
    }
}


public protocol RunInfoStyle: Sendable {
    typealias Configuration = RunInfoStyleConfiguration
    
    associatedtype Body: View
    
    @MainActor @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
}

// MARK: - Built-in styles

public extension RunInfoStyle where Self == RegularRunInfoStyle {
    static var `default`: RegularRunInfoStyle { RegularRunInfoStyle() }
}

public extension RunInfoStyle where Self == CompactRunInfoStyle {
    static var compact: CompactRunInfoStyle { CompactRunInfoStyle() }
}
