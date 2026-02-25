import Foundation

enum GPX: Equatable, Sendable {

    struct Point: Equatable, Sendable {
        
        let cadence: Int
        
        let elevation: Double
        
        let heartRate: Int
        
        let latitude: Double
        
        let longitude: Double
        
        let time: Date
    }

    struct Track: Equatable, Sendable {
        
        fileprivate(set) var name: String
        
        fileprivate(set) var points: [Point]
        
        fileprivate(set) var type: String
    }
    
    final class Parser: Sendable {
        private let dateFormatter: ISO8601DateFormatter
        
        init(dateFormatter: ISO8601DateFormatter = .init()) {
            self.dateFormatter = dateFormatter
        }

        func parse(fileNamed name: String) -> [Track] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "gpx"),
                  let data = try? Data(contentsOf: url) else { return [] }
            return parse(data: data)
        }

        func parse(fileNamed name: String) -> Track? {
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
