import SwiftUI
import RunKit

public struct CompactRunInfoViewStyle: RunInfoViewStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        CompactRunInfoView(configuration: configuration)
    }
}

private struct CompactRunInfoView: View {
    
    private let configuration: RunInfoStyleConfiguration
    
    init(configuration: RunInfoStyleConfiguration) {
        self.configuration = configuration
    }
    
    var body: some View {
        VStack(alignment: .center) {
            configuration.name
                .font(.subheadline.weight(.semibold))

            info
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var info: some View {
        let dot = Text(" • ")
        return configuration.date
            + dot + configuration.distance
            + dot + configuration.duration
    }
}
