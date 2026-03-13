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

    @Relationship(inverse: \Habit.entries)
    var habit: Habit?

    init(date: Date, habit: Habit) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = false
        self.habit = habit
    }

    func complete() {
        isCompleted = true
        completedAt = Date()
    }

    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }
}
