import Foundation

/// The provenance of a stored run — where it came from and how to
/// fetch its track data if not yet cached locally.
///
public enum RunOrigin: Codable, Hashable, Sendable {

    /// A run fetched from an external activity tracker.
    case tracker(ActivitySource)

    /// A run imported from a local file (GPX or similar).
    case file(url: URL)

    /// A run bundled with the app by resource name.
    case bundled(name: String)

    /// A run imported from a `.runi` document.
    case document
}
