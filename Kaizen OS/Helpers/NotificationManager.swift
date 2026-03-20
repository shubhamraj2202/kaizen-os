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

    // leadMinutesList: each value schedules a separate notification (e.g. [0, 10] = at time + 10 min before)
    func scheduleHabitReminder(habitName: String, emoji: String, time: Date, weekdays: [Int], habitID: String, leadMinutesList: [Int] = [0]) {
        removeHabitReminder(habitID: habitID)

        let calendar = Calendar.current
        let daysToSchedule = weekdays.isEmpty ? Array(0...6) : weekdays
        let offsets = leadMinutesList.isEmpty ? [0] : leadMinutesList

        for leadMinutes in offsets {
            let adjustedTime = calendar.date(byAdding: .minute, value: -leadMinutes, to: time) ?? time
            let hour = calendar.component(.hour, from: adjustedTime)
            let minute = calendar.component(.minute, from: adjustedTime)

            let content = UNMutableNotificationContent()
            content.title = "\(emoji) \(habitName)"
            content.body = leadMinutes == 0 ? "Time to keep your streak going!" : "Starting in \(leadMinutes) min — get ready!"
            content.sound = .default

            for weekday in daysToSchedule {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                components.weekday = weekday + 1  // Calendar: 1=Sun...7=Sat

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(habitID)_\(weekday)_\(leadMinutes)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func removeHabitReminder(habitID: String) {
        // Remove all weekday × lead-time combinations
        let possibleLeads = [0, 5, 10, 15, 30]
        let identifiers = (0...6).flatMap { weekday in
            possibleLeads.map { lead in "\(habitID)_\(weekday)_\(lead)" }
        }
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
