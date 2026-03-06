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

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchEvents()
            }
        }
    }

    deinit {
        pollTimer?.invalidate()
    }
}
