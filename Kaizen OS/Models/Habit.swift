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
    private func isScheduled(on date: Date) -> Bool {
        guard !scheduledWeekdays.isEmpty else { return true }  // empty = every day
        let weekday = Calendar.current.component(.weekday, from: date) - 1  // 1-based → 0-based
        return scheduledWeekdays.contains(weekday)
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedDates = Set(
            entries
                .filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
        )
        var streak = 0
        var checkDate = today
        // Walk backwards, skipping rest days, breaking only on a missed scheduled day
        for _ in 0..<365 {
            if isScheduled(on: checkDate) {
                if completedDates.contains(checkDate) {
                    streak += 1
                } else {
                    // Missed a scheduled day — streak ends
                    // Exception: if checkDate is today and habit not done yet, don't penalise
                    if checkDate != today { break }
                }
            }
            // Move to previous day
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        // Get all scheduled days from habit creation to today, walk forward
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: createdAt)
        let completedDates = Set(
            entries
                .filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
        )
        var longest = 0
        var current = 0
        var checkDate = start
        while checkDate <= today {
            if isScheduled(on: checkDate) {
                if completedDates.contains(checkDate) {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 0  // missed a scheduled day
                }
            }
            // Skip to next day
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
        // Count only days the habit was actually scheduled in the window
        var scheduledCount = 0
        var checkDate = start
        while checkDate <= today {
            if isScheduled(on: checkDate) { scheduledCount += 1 }
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
