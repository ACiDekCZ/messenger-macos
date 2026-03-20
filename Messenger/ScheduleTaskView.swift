import SwiftUI

struct ScheduleTaskView: View {
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    @State private var taskTitle: String = ""
    @State private var taskDate: Date = defaultDate()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "schedule.title"))
                .font(.headline)

            TextField(String(localized: "schedule.placeholder"), text: $taskTitle)
                .textFieldStyle(.roundedBorder)

            DatePicker(
                String(localized: "schedule.time"),
                selection: $taskDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )

            HStack {
                Button(String(localized: "schedule.cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(String(localized: "schedule.add")) {
                    guard !taskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    scheduleManager.addTask(title: taskTitle.trimmingCharacters(in: .whitespaces), date: taskDate)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(taskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !scheduleManager.pendingTasks.isEmpty {
                Divider()

                Text(String(localized: "schedule.upcoming"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(scheduleManager.pendingTasks) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.body)
                                    Text(task.date, style: .date) + Text(" ") + Text(task.date, style: .time)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)

                                Spacer()

                                Button(role: .destructive) {
                                    scheduleManager.removeTask(task)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private static func defaultDate() -> Date {
        // Default to next hour
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.hour = (components.hour ?? 0) + 1
        components.minute = 0
        return calendar.date(from: components) ?? now.addingTimeInterval(3600)
    }
}
