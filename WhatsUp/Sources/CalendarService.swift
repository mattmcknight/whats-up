import EventKit
import SwiftUI
import Combine

@MainActor
final class CalendarService: ObservableObject {
    @Published var todayEvents: [CalendarEvent] = []

    private let store = EKEventStore()
    private nonisolated(unsafe) var pollTimer: Timer?
    private var authorized = false

    init() {
        Task { await requestAccessAndFetch() }
        observeStoreChanges()
    }

    private func requestAccessAndFetch() async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorized = granted
            if granted {
                fetchEvents()
                startPolling()
            } else {
                print("Calendar access denied")
            }
        } catch {
            print("Calendar access error: \(error)")
        }
    }

    func fetchEvents() {
        guard authorized else { return }

        store.reset()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        let ekEvents = store.events(matching: predicate)

        todayEvents = ekEvents
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { CalendarEvent(from: $0) }
    }

    private func observeStoreChanges() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.fetchEvents()
            }
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchEvents()
            }
        }
    }

    func restartPolling() {
        pollTimer?.invalidate()
        guard authorized else { return }
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
    }
}
