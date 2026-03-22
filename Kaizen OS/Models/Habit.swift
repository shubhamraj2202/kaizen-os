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

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        let completedDates = Set(
            entries
                .filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
        )
        while completedDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let sorted = entries
            .filter { $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
        guard !sorted.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
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
        let recent = entries.filter {
            let d = calendar.startOfDay(for: $0.date)
            return d >= start && d <= today
        }
        return Double(recent.filter { $0.isCompleted }.count) / 30.0
    }
}
