//
//  NotificationManager.swift
//  Kaizen OS
//

import UserNotifications

@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private(set) var isAuthorized = false

    @MainActor
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Notification auth error: \(error)")
        }
    }

    func scheduleHabitReminder(habitName: String, emoji: String, time: Date, weekdays: [Int], habitID: String, leadMinutes: Int = 0) {
        removeHabitReminder(habitID: habitID)

        let calendar = Calendar.current
        let adjustedTime = calendar.date(byAdding: .minute, value: -leadMinutes, to: time) ?? time
        let hour = calendar.component(.hour, from: adjustedTime)
        let minute = calendar.component(.minute, from: adjustedTime)

        let daysToSchedule = weekdays.isEmpty ? Array(0...6) : weekdays

        for weekday in daysToSchedule {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            // Convert 0=Sun...6=Sat to Calendar weekday (1=Sun...7=Sat)
            components.weekday = weekday + 1

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = "\(emoji) \(habitName)"
            content.body = "Time to keep your streak going!"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(habitID)_\(weekday)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    func removeHabitReminder(habitID: String) {
        let identifiers = (0...6).map { "\(habitID)_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func scheduleDailyReminder(time: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = calendar.component(.hour, from: time)
        components.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "改善 Kaizen OS"
        content.body = "Ready to build your day? Check in now."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
