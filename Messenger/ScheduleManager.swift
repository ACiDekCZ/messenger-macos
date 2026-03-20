import Foundation
import UserNotifications

struct ScheduledTask: Codable, Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var notificationId: String
    var isCompleted: Bool

    init(title: String, date: Date) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.notificationId = "scheduled-\(id.uuidString)"
        self.isCompleted = false
    }
}

class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    private static let storageKey = "scheduledTasks"

    @Published var tasks: [ScheduledTask] = []

    private init() {
        loadTasks()
    }

    // MARK: - Persistence

    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([ScheduledTask].self, from: data) else {
            return
        }
        tasks = decoded
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: - Task Management

    func addTask(title: String, date: Date) {
        let task = ScheduledTask(title: title, date: date)
        tasks.append(task)
        saveTasks()
        scheduleNotification(for: task)
        #if DEBUG
        print("[Schedule] Added task: \(title) at \(date)")
        #endif
    }

    func removeTask(_ task: ScheduledTask) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.notificationId])
        tasks.removeAll { $0.id == task.id }
        saveTasks()
        #if DEBUG
        print("[Schedule] Removed task: \(task.title)")
        #endif
    }

    func completeTask(_ task: ScheduledTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted = true
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.notificationId])
        saveTasks()
        #if DEBUG
        print("[Schedule] Completed task: \(task.title)")
        #endif
    }

    /// Remove completed and past tasks
    func cleanUp() {
        let toRemove = tasks.filter { $0.isCompleted }
        for task in toRemove {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.notificationId])
        }
        tasks.removeAll { $0.isCompleted }
        saveTasks()
    }

    // MARK: - Notifications

    private func scheduleNotification(for task: ScheduledTask) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "schedule.reminder")
        content.body = task.title
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: task.notificationId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("[Schedule] Failed to schedule notification: \(error)")
            } else {
                print("[Schedule] Notification scheduled for: \(task.date)")
            }
            #endif
        }
    }

    /// Pending (future, not completed) tasks sorted by date
    var pendingTasks: [ScheduledTask] {
        tasks.filter { !$0.isCompleted && $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
}
