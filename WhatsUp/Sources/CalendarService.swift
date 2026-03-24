import EventKit
import SwiftUI

@MainActor
final class CalendarService: ObservableObject {
    @Published var todayEvents: [CalendarEvent] = []

    private var store = EKEventStore()
    private nonisolated(unsafe) var storeObserverToken: NSObjectProtocol?
    private nonisolated(unsafe) var pollTimer: Timer?
    private var authorized = false
    private var lastRefresh: Date = .distantPast

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
            }
        } catch {
            print("[WhatsUp] Calendar access error: \(error)")
        }
    }

    /// Recreates the EKEventStore to bust stale cache. Rate-limited to once per second.
    func refreshAndFetch() {
        let now = Date()
        guard now.timeIntervalSince(lastRefresh) > 1 else { return }
        lastRefresh = now

        if let token = storeObserverToken {
            NotificationCenter.default.removeObserver(token)
            storeObserverToken = nil
        }

        store = EKEventStore()
        observeStoreChanges()
        authorized = false

        Task {
            do {
                let granted = try await store.requestFullAccessToEvents()
                authorized = granted
                if granted { fetchEvents() }
            } catch {
                print("[WhatsUp] Re-auth error: \(error)")
            }
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

        todayEvents = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { CalendarEvent(from: $0) }
    }

    private func observeStoreChanges() {
        storeObserverToken = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.fetchEvents() }
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.fetchEvents() }
        }
    }

    func restartPolling() {
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
