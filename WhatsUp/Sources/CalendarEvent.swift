import EventKit
import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    let url: URL?
    let isAllDay: Bool

    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? "Untitled"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.url = ekEvent.url
        self.isAllDay = ekEvent.isAllDay
    }

    var isActive: Bool {
        let now = Date()
        return now >= startDate && now < endDate
    }

    var isUpcoming: Bool {
        Date() < startDate
    }

    var minutesUntilStart: Int {
        let interval = startDate.timeIntervalSince(Date())
        return max(0, Int(ceil(interval / 60)))
    }

    var minutesSinceStart: Int {
        let interval = Date().timeIntervalSince(startDate)
        return max(0, Int(floor(interval / 60)))
    }
}
