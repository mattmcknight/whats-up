import SwiftUI
import Combine

struct DisplayState {
    let iconName: String
    let color: Color
    let countdownText: String
}

@MainActor
final class MeetingMonitor: ObservableObject {
    @Published var displayState = DisplayState(
        iconName: "calendar",
        color: .secondary,
        countdownText: "--"
    )

    private var calendarService: CalendarService?
    var alarmController: AlarmController?
    private nonisolated(unsafe) var tickTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {}

    func bind(to calendarService: CalendarService, alarm: AlarmController) {
        self.calendarService = calendarService
        self.alarmController = alarm
        calendarService.$todayEvents
            .sink { [weak self] _ in self?.tick() }
            .store(in: &cancellables)
        startTicking()
    }

    private func startTicking() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func tick() {
        guard let calendarService else { return }
        let events = calendarService.todayEvents
        // Find current active meeting — trigger alarm if needed
        if let active = events.first(where: { $0.isActive }) {
            let mins = active.minutesSinceStart
            displayState = DisplayState(
                iconName: "bell.fill",
                color: .red,
                countdownText: mins == 0 ? "NOW" : "+\(mins)m"
            )

            if let alarm = alarmController, alarm.shouldAlarm(for: active) {
                alarm.trigger(for: active)
            }
            return
        }

        // Find next upcoming meeting
        if let next = events.first(where: { $0.isUpcoming }) {
            let mins = next.minutesUntilStart
            let color: Color
            let icon: String

            switch mins {
            case 0...2:
                color = .red
                icon = "bell.fill"
            case 3...5:
                color = .orange
                icon = "bell"
            case 6...15:
                color = .yellow
                icon = "calendar.badge.clock"
            default:
                color = .green
                icon = "calendar"
            }

            let text: String
            if mins < 60 {
                text = "\(mins)m"
            } else {
                let h = mins / 60
                let m = mins % 60
                text = m > 0 ? "\(h)h\(m)m" : "\(h)h"
            }

            displayState = DisplayState(
                iconName: icon,
                color: color,
                countdownText: text
            )
            return
        }

        // No more meetings today
        displayState = DisplayState(
            iconName: "calendar",
            color: .secondary,
            countdownText: "--"
        )
    }

    deinit {
        tickTimer?.invalidate()
    }
}
