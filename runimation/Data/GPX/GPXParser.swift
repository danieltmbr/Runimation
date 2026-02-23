import Foundation

struct GPXTrackPoint {
    let latitude: Double
    let longitude: Double
    let elevation: Double
    let timestamp: Date
    let heartRate: Int
    let cadence: Int
}

struct GPXTrack {
    let name: String
    let type: String
    let points: [GPXTrackPoint]
}

final class GPXParser: NSObject, XMLParserDelegate {

    private var points: [GPXTrackPoint] = []
    private var trackName = ""
    private var trackType = ""

    // Parsing state
    private var currentText = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double?
    private var currentTime: Date?
    private var currentHR: Int?
    private var currentCad: Int?
    private var inTrackPointExtension = false

    private var result: GPXTrack?

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Public

    static func parse(fileNamed name: String) -> GPXTrack? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gpx"),
              let data = try? Data(contentsOf: url) else { return nil }
        return GPXParser().parse(data: data)
    }

    func parse(data: Data) -> GPXTrack? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.parse()
        return result
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        currentText = ""

        switch elementName {
        case "trkpt":
            currentLat = attributes["lat"].flatMap(Double.init)
            currentLon = attributes["lon"].flatMap(Double.init)
            currentEle = nil
            currentTime = nil
            currentHR = nil
            currentCad = nil
        case "TrackPointExtension":
            inTrackPointExtension = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "ele":
            currentEle = Double(text)
        case "time":
            currentTime = Self.dateFormatter.date(from: text)
        case "hr" where inTrackPointExtension:
            currentHR = Int(text)
        case "cad" where inTrackPointExtension:
            currentCad = Int(text)
        case "TrackPointExtension":
            inTrackPointExtension = false
        case "trkpt":
            if let lat = currentLat,
               let lon = currentLon,
               let ele = currentEle,
               let time = currentTime {
                let point = GPXTrackPoint(
                    latitude: lat,
                    longitude: lon,
                    elevation: ele,
                    timestamp: time,
                    heartRate: currentHR ?? 0,
                    cadence: currentCad ?? 0
                )
                points.append(point)
            }
        case "name":
            trackName = text
        case "type":
            trackType = text
        case "trk":
            result = GPXTrack(name: trackName, type: trackType, points: points)
        default:
            break
        }
    }
}
