import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let calendarService = CalendarService()
    let meetingMonitor = MeetingMonitor()
    let alarmController = AlarmController()
    let taskStore = TaskStore()

    init() {
        meetingMonitor.bind(to: calendarService, alarm: alarmController)
        observeSystemWake()
    }

    private func observeSystemWake() {
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                // macOS fires didWakeNotification multiple times; CalendarService.refreshAndFetch
                // is rate-limited so only the first call per second does real work.
                self?.calendarService.restartPolling()
                self?.calendarService.refreshAndFetch()
                // EKEventStoreChanged will fire once the calendar daemon finishes syncing,
                // triggering a follow-up fetch automatically.
            }
        }
    }
}
