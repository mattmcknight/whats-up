import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
    @Published var currentTask: String = "" {
        didSet {
            UserDefaults.standard.set(currentTask, forKey: "currentTask")
        }
    }

    init() {
        currentTask = UserDefaults.standard.string(forKey: "currentTask") ?? ""
    }
}
