import EventKit
import SwiftUI
import Combine
import OSLog

private let osLog = Logger(subsystem: "com.whatsup", category: "CalendarService")
private let logFile: URL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Logs/WhatsUp.log")

private func wlog(_ msg: String) {
    let line = "\(Date()) \(msg)\n"
    osLog.info("\(msg, privacy: .public)")
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fh = try? FileHandle(forWritingTo: logFile) {
                fh.seekToEndOfFile()
                fh.write(data)
                try? fh.close()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
}

@MainActor
final class CalendarService: ObservableObject {
    @Published var todayEvents: [CalendarEvent] = []

    private var store = EKEventStore()
    private nonisolated(unsafe) var storeObserverToken: NSObjectProtocol?
    private nonisolated(unsafe) var pollTimer: Timer?
    private var authorized = false
    private var refreshTask: Task<Void, Never>?

    init() {
        Task { await requestAccessAndFetch() }
        observeStoreChanges()
    }

    private func requestAccessAndFetch() async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorized = granted
            wlog("Calendar access granted: \(granted)")
            if granted {
                fetchEvents()
                startPolling()
            } else {
                wlog("Calendar access denied")
            }
        } catch {
            wlog("Calendar access error: \(error)")
        }
    }

    /// Force refresh by recreating the EKEventStore. Debounced so rapid calls collapse.
    func refreshAndFetch() {
        refreshTask?.cancel()
        refreshTask = Task {
            wlog("refreshAndFetch: recreating EKEventStore")

            // Remove old store observer
            if let token = storeObserverToken {
                NotificationCenter.default.removeObserver(token)
                storeObserverToken = nil
            }

            store = EKEventStore()
            observeStoreChanges()
            authorized = false

            do {
                let granted = try await store.requestFullAccessToEvents()
                guard !Task.isCancelled else { return }
                authorized = granted
                wlog("refreshAndFetch: re-auth granted=\(granted)")
                if granted { fetchEvents() }
            } catch {
                wlog("refreshAndFetch: re-auth error: \(error)")
            }
        }
    }

    func fetchEvents() {
        guard authorized else {
            wlog("fetchEvents called but not authorized")
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        wlog("fetchEvents: querying \(startOfDay) → \(endOfDay)")

        let allCalendars = store.calendars(for: .event)
        wlog("fetchEvents: \(allCalendars.count) calendars: \(allCalendars.map(\.title).joined(separator: ", "))")

        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        let ekEvents = store.events(matching: predicate)

        wlog("fetchEvents: \(ekEvents.count) raw events")
        for ev in ekEvents {
            wlog("  \"\(ev.title ?? "nil")\" start=\(ev.startDate) allDay=\(ev.isAllDay) cal=\(ev.calendar.title)")
        }

        let filtered = ekEvents
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { CalendarEvent(from: $0) }

        wlog("fetchEvents: \(filtered.count) after allDay filter → publishing")
        todayEvents = filtered
    }

    private func observeStoreChanges() {
        storeObserverToken = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            wlog("EKEventStoreChanged received")
            Task { @MainActor in
                self?.fetchEvents()
            }
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            wlog("poll timer fired")
            Task { @MainActor in
                self?.fetchEvents()
            }
        }
    }

    func restartPolling() {
        wlog("restartPolling called")
        pollTimer?.invalidate()
        guard authorized else { return }
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
        if let token = storeObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
