import SwiftUI

@main
struct WhatsUpApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopover(appState: appState)
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
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's Up")
                .font(.headline)

            // Current task
            HStack(spacing: 6) {
                Image(systemName: "pencil.line")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Working on...", text: Binding(
                    get: { appState.taskStore.currentTask },
                    set: { appState.taskStore.currentTask = $0 }
                ))
                    .textFieldStyle(.plain)
                    .font(.callout)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            Divider()

            let upcoming = appState.calendarService.todayEvents
                .filter { $0.isUpcoming || $0.isActive }

            if upcoming.isEmpty {
                Text("No more meetings today")
                    .foregroundStyle(.secondary)
            } else {
                Text("Meetings")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(upcoming) { event in
                    MeetingRow(event: event, appState: appState)
                }
            }

            Divider()
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
    let appState: AppState

    var body: some View {
        Button(action: { joinMeeting() }) {
            HStack {
                if event.isActive {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                }
                let zoomLink = ZoomDetector.extractLink(from: event)
                Image(systemName: zoomLink != nil ? "video.fill" : "person.2.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption2)
                Text(event.title)
                    .lineLimit(1)
                Spacer()
                Text(event.startDate, style: .time)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func joinMeeting() {
        if let url = ZoomDetector.extractLink(from: event) {
            appState.alarmController.joinZoom(url: url)
        } else {
            appState.alarmController.acknowledge()
        }
    }
}
