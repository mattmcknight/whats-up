import SwiftUI
import AppKit

enum EventState {
    case pending
    case joined
    case acknowledged
    case skipped
}

@MainActor
final class AlarmController: ObservableObject {
    @Published var alarmingEvent: CalendarEvent?
    @Published var isAlarming = false

    private var eventStates: [String: EventState] = [:]
    private var statesDate: Date = Calendar.current.startOfDay(for: Date())
    private let soundPlayer = SoundPlayer()
    private var alarmWindow: NSWindow?

    func shouldAlarm(for event: CalendarEvent) -> Bool {
        pruneIfNewDay()
        let state = eventStates[event.id] ?? .pending
        return event.isActive && state == .pending
    }

    func trigger(for event: CalendarEvent) {
        guard !isAlarming else { return }
        alarmingEvent = event
        isAlarming = true
        soundPlayer.startLooping()
        showAlarmWindow()
    }

    func joinZoom(url: URL) {
        guard let event = alarmingEvent else { return }
        eventStates[event.id] = .joined
        NSWorkspace.shared.open(url)
        dismiss()
    }

    func acknowledge() {
        guard let event = alarmingEvent else { return }
        eventStates[event.id] = .acknowledged
        dismiss()
    }

    func skip() {
        guard let event = alarmingEvent else { return }
        eventStates[event.id] = .skipped
        dismiss()
    }

    func dismiss() {
        isAlarming = false
        alarmingEvent = nil
        soundPlayer.stop()
        alarmWindow?.close()
        alarmWindow = nil
    }

    private func showAlarmWindow() {
        guard let event = alarmingEvent else { return }

        let zoomLink = ZoomDetector.extractLink(from: event)
        let alarmView = AlarmPanelView(
            event: event,
            zoomLink: zoomLink,
            controller: self
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 200),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: alarmView)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear

        // Center at top of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 210
            let y = screenFrame.maxY - 220
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        alarmWindow = window
    }

    private func pruneIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        if today > statesDate {
            eventStates.removeAll()
            statesDate = today
        }
    }
}
