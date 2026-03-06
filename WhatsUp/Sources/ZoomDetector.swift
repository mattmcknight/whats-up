import Foundation

enum ZoomDetector {
    // Matches zoom.us/j/123456 and variants like us02web.zoom.us
    private static let zoomPattern = try! NSRegularExpression(
        pattern: #"https?://[\w.-]*zoom\.us/[jw]/[\d]+"#,
        options: .caseInsensitive
    )

    static func extractLink(from event: CalendarEvent) -> URL? {
        let candidates = [
            event.url?.absoluteString,
            event.location,
            event.notes
        ]

        for candidate in candidates {
            guard let text = candidate else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = zoomPattern.firstMatch(in: text, range: range) {
                let matchRange = Range(match.range, in: text)!
                return URL(string: String(text[matchRange]))
            }
        }
        return nil
    }
}
