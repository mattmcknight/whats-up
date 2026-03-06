import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    let calendarService = CalendarService()
    let meetingMonitor = MeetingMonitor()
    let alarmController = AlarmController()
    let taskStore = TaskStore()

    private nonisolated(unsafe) var midnightTimer: Timer?

    init() {
        meetingMonitor.bind(to: calendarService, alarm: alarmController)
        scheduleMidnightRollover()
    }

    private func scheduleMidnightRollover() {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else { return }

        midnightTimer = Timer(fire: tomorrow, interval: 86400, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.rollover()
            }
        }
        RunLoop.main.add(midnightTimer!, forMode: .common)
    }

    private func rollover() {
        alarmController.resetForNewDay()
        calendarService.fetchEvents()
    }

    deinit {
        midnightTimer?.invalidate()
    }
}
