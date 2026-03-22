//
//  Habit.swift
//  Kaizen OS
//

import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int
    var isActive: Bool
    var reminderTime: Date?
    var reminderDays: [Int]
    var reminderLeadMinutesList: [Int]  // each value = one notification offset (e.g. [0, 10])
    var scheduledWeekdays: [Int]    // empty = every day; non-empty = only on those days (0=Sun…6=Sat)
    var endDate: Date?              // nil = unlimited
    var pausedUntil: Date?          // nil = not paused; non-nil = paused until (and including) this date

    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntry] = []

    init(name: String, emoji: String = "✅", colorHex: String = "#00E5C8", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.isActive = true
        self.reminderTime = nil
        self.reminderDays = []
        self.reminderLeadMinutesList = []
        self.scheduledWeekdays = []
        self.endDate = nil
        self.pausedUntil = nil
    }

    var isPaused: Bool {
        guard let until = pausedUntil else { return false }
        return Calendar.current.startOfDay(for: until) >= Calendar.current.startOfDay(for: Date())
    }

    // Returns "18d left", "1d left", or "🎉 Done!" when habit has an end date
    var durationBadge: String? {
        guard let end = endDate else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let endDay = cal.startOfDay(for: end)
        let diff = cal.dateComponents([.day], from: today, to: endDay).day ?? 0
        if diff <= 0 { return "🎉 Done!" }
        return "\(diff)d left"
    }

    // Returns true if this habit is scheduled on the given calendar weekday (0=Sun…6=Sat)
    func isScheduled(on date: Date) -> Bool {
        guard !scheduledWeekdays.isEmpty else { return true }  // empty = every day
        let weekday = Calendar.current.component(.weekday, from: date) - 1  // 1-based → 0-based
        return scheduledWeekdays.contains(weekday)
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedDates = Set(entries.filter { $0.isCompleted }.map { calendar.startOfDay(for: $0.date) })
        let skippedDates  = Set(entries.filter { $0.isSkipped  }.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var checkDate = today
        for _ in 0..<365 {
            if isScheduled(on: checkDate) {
                if completedDates.contains(checkDate) {
                    streak += 1
                } else if skippedDates.contains(checkDate) {
                    // Intentionally skipped — transparent, doesn't add to streak, doesn't break it
                } else {
                    if checkDate != today { break }  // missed; today's still in progress so don't penalise
                }
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: createdAt)
        let completedDates = Set(entries.filter { $0.isCompleted }.map { calendar.startOfDay(for: $0.date) })
        let skippedDates  = Set(entries.filter { $0.isSkipped  }.map { calendar.startOfDay(for: $0.date) })
        var longest = 0
        var current = 0
        var checkDate = start
        while checkDate <= today {
            if isScheduled(on: checkDate) {
                if completedDates.contains(checkDate) {
                    current += 1
                    longest = max(longest, current)
                } else if skippedDates.contains(checkDate) {
                    // Skip over — doesn't reset streak
                } else {
                    current = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = next
        }
        return longest
    }

    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return entries.contains {
            $0.isCompleted && Calendar.current.startOfDay(for: $0.date) == day
        }
    }

    var completionRate30Days: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return 0 }
        let skippedDates = Set(entries.filter { $0.isSkipped }.map { calendar.startOfDay(for: $0.date) })
        // Count scheduled non-skipped days as denominator
        var scheduledCount = 0
        var checkDate = start
        while checkDate <= today {
            if isScheduled(on: checkDate) && !skippedDates.contains(checkDate) { scheduledCount += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = next
        }
        guard scheduledCount > 0 else { return 0 }
        let completed = entries.filter {
            let d = calendar.startOfDay(for: $0.date)
            return d >= start && d <= today && $0.isCompleted
        }.count
        return Double(completed) / Double(scheduledCount)
    }
}
