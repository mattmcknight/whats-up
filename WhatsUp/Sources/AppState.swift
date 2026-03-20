import SwiftUI
import Combine

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
                self?.calendarService.restartPolling()
                self?.calendarService.refreshAndFetch()
                // Calendar daemon may not have synced yet — refresh again after a delay
                try? await Task.sleep(for: .seconds(3))
                self?.calendarService.refreshAndFetch()
            }
        }
    }
}
