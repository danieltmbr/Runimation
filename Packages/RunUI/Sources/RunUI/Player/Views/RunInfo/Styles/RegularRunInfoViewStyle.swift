import SwiftUI
import RunKit

public struct RegularRunInfoViewStyle: RunInfoViewStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        RegularRunInfoView(configuration: configuration)
    }
}

private struct RegularRunInfoView: View {
    
    private let configuration: RunInfoStyleConfiguration
    
    init(configuration: RunInfoStyleConfiguration) {
        self.configuration = configuration
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration.name
                .font(.headline)
            
            Group {
                configuration.date
                info
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var info: some View {
        let dot = Text(" • ")
        return configuration.distance + dot + configuration.duration
    }
}
