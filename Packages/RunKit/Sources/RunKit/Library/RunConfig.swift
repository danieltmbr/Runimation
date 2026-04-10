import Foundation

/// Opaque snapshot of the persisted configuration for a run.
///
/// All fields are stored as raw JSON `Data?` blobs so that `RunKit`
/// remains independent of the concrete config types that live in the
/// app layer (`VisualisationConfig`, `TransformerConfig`, etc.).
/// The app decodes each blob into its concrete type via `RunItem+Config`.
///
public struct RunConfig: Sendable {
    public let visualisationConfigData: Data?
    public let transformersConfigData: Data?
    public let interpolatorConfigData: Data?
    public let playDuration: TimeInterval?

    public init(
        visualisationConfigData: Data?,
        transformersConfigData: Data?,
        interpolatorConfigData: Data?,
        playDuration: TimeInterval?
    ) {
        self.visualisationConfigData = visualisationConfigData
        self.transformersConfigData = transformersConfigData
        self.interpolatorConfigData = interpolatorConfigData
        self.playDuration = playDuration
    }
}
