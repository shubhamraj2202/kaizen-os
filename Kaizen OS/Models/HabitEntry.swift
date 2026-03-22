//
//  HabitEntry.swift
//  Kaizen OS
//

import Foundation
import SwiftData

@Model
final class HabitEntry {
    var id: UUID
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?
    var note: String?
    var isSkipped: Bool  // true = intentionally skipped (skip day / pause) — doesn't break streak

    @Relationship(inverse: \Habit.entries)
    var habit: Habit?

    init(date: Date, habit: Habit) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = false
        self.isSkipped = false
        self.habit = habit
    }

    func complete() {
        isCompleted = true
        isSkipped = false
        completedAt = Date()
    }

    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }

    func skip() {
        isSkipped = true
        isCompleted = false
        completedAt = nil
    }
}
