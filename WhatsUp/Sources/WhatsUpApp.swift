import SwiftUI

@main
struct WhatsUpApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Disable App Nap — timers must fire on time for meeting alerts
        ProcessInfo.processInfo.disableAutomaticTermination("Meeting alerts active")
        ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Time-sensitive meeting alerts"
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopover(
                calendarService: appState.calendarService,
                taskStore: appState.taskStore
            )
        } label: {
            MenuBarLabel(meetingMonitor: appState.meetingMonitor)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var meetingMonitor: MeetingMonitor

    var body: some View {
        let state = meetingMonitor.displayState
        HStack(spacing: 4) {
            Image(systemName: state.iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(state.color)
            Text(state.countdownText)
                .monospacedDigit()
        }
    }
}

struct MenuBarPopover: View {
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var taskStore: TaskStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's Up")
                .font(.headline)

            HStack(spacing: 6) {
                Image(systemName: "pencil.line")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Working on...", text: $taskStore.currentTask)
                    .textFieldStyle(.plain)
                    .font(.callout)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            Divider()

            let upcoming = calendarService.todayEvents
                .filter { $0.isUpcoming || $0.isActive }

            if upcoming.isEmpty {
                Text("No more meetings today")
                    .foregroundStyle(.secondary)
            } else {
                Text("Meetings")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(upcoming) { event in
                    MeetingRow(event: event)
                }
            }

            Divider()
            Button("Refresh Calendars") {
                calendarService.refreshAndFetch()
            }
            .keyboardShortcut("r")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(minWidth: 280)
    }
}

struct MeetingRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack {
            if event.isActive {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
            }
            Text(event.title)
                .lineLimit(1)
            Spacer()
            Text(event.startDate, style: .time)
                .foregroundStyle(.secondary)
            if let url = ZoomDetector.extractLink(from: event) {
                Button(action: { NSWorkspace.shared.open(url) }) {
                    Image(systemName: "video.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
