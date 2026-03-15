import Foundation

/// Namespace for GPX data types and file parsing.
///
/// `GPX.Point` and `GPX.Track` are the raw data model exchanged between
/// data-fetching layers (e.g. StravaKit) and run-processing layers (e.g. RunKit).
/// `GPX.Parser` reads `.gpx` files from the main bundle.
///
public enum GPX: Equatable, Sendable {

    public struct Point: Equatable, Sendable {

        public let cadence: Int

        public let elevation: Double

        public let heartRate: Int

        public let latitude: Double

        public let longitude: Double

        public let time: Date

        public init(
            cadence: Int,
            elevation: Double,
            heartRate: Int,
            latitude: Double,
            longitude: Double,
            time: Date
        ) {
            self.cadence = cadence
            self.elevation = elevation
            self.heartRate = heartRate
            self.latitude = latitude
            self.longitude = longitude
            self.time = time
        }
    }

    public struct Track: Equatable, Sendable {

        public fileprivate(set) var name: String

        public fileprivate(set) var points: [Point]

        public fileprivate(set) var type: String

        public init(name: String, points: [Point] = [], type: String = "") {
            self.name = name
            self.points = points
            self.type = type
        }
    }

    public final class Parser {

        private let dateFormatter: ISO8601DateFormatter

        public init(dateFormatter: ISO8601DateFormatter = .init()) {
            self.dateFormatter = dateFormatter
        }

        public func parse(fileNamed name: String) -> [Track] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "gpx"),
                  let data = try? Data(contentsOf: url) else { return [] }
            return parse(data: data)
        }

        public func parse(fileNamed name: String) -> Track? {
            parse(fileNamed: name).first
        }

        private func parse(data: Data) -> [Track] {
            let delegate = Delegate(dateFormatter: dateFormatter)
            let parser = XMLParser(data: data)
            parser.delegate = delegate
            parser.shouldProcessNamespaces = false
            parser.parse()
            return delegate.results
        }
    }
}

// MARK: - Private XMLParserDelegate

private extension GPX {

    final class Delegate: NSObject, XMLParserDelegate {

        private struct PointInProgress {

            var latitude: Double?

            var longitude: Double?

            var elevation: Double?

            var time: Date?

            var heartRate: Int?

            var cadence: Int?

            func build() -> Point? {
                guard let lat = latitude,
                      let lon = longitude,
                      let ele = elevation,
                      let time = time else { return nil }
                return Point(
                    cadence: cadence ?? 0,
                    elevation: ele,
                    heartRate: heartRate ?? 0,
                    latitude: lat,
                    longitude: lon,
                    time: time
                )
            }
        }

        private let dateFormatter: ISO8601DateFormatter

        private var point: PointInProgress?

        private var text: String = ""

        private var track: Track?

        var results: [Track] = []

        init(dateFormatter: ISO8601DateFormatter) {
            self.dateFormatter = dateFormatter
            super.init()
        }

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName: String?,
            attributes: [String: String] = [:]
        ) {
            text = ""

            switch elementName {
            case "trk":
                track = Track(name: "", points: [], type: "")
            case "trkpt":
                point = PointInProgress(
                    latitude: attributes["lat"].flatMap(Double.init),
                    longitude: attributes["lon"].flatMap(Double.init)
                )
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName: String?
        ) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            switch elementName {
            case "name":
                track?.name = trimmed
            case "type":
                track?.type = trimmed
            case "ele":
                point?.elevation = Double(trimmed)
            case "time":
                point?.time = dateFormatter.date(from: trimmed)
            case "gpxtpx:hr":
                point?.heartRate = Int(trimmed)
            case "gpxtpx:cad":
                point?.cadence = Int(trimmed)
            case "trkpt":
                if let p = point?.build() { track?.points.append(p) }
                point = nil
            case "trk":
                if let t = track { results.append(t) }
                track = nil
            default:
                break
            }
        }
    }
}
