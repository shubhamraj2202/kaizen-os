//
//  DailyTask.swift
//  Kaizen OS
//

import Foundation
import SwiftData

enum TaskPriority: Int, Codable, CaseIterable {
    case top3 = 0
    case normal = 1
}

enum TaskCategory: String, Codable, CaseIterable {
    case work = "Work"
    case health = "Health"
    case planning = "Planning"
    case personal = "Personal"
    case finance = "Finance"
    case other = "Other"

    var emoji: String {
        switch self {
        case .work: return "💼"
        case .health: return "🏃"
        case .planning: return "📋"
        case .personal: return "⭐️"
        case .finance: return "💰"
        case .other: return "📌"
        }
    }
}

@Model
final class DailyTask {
    var id: UUID
    var title: String
    var notes: String       // optional description / checklist text
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?
    var priority: TaskPriority
    var category: TaskCategory
    var sortOrder: Int
    var createdAt: Date

    init(title: String, notes: String = "", date: Date = Date(), priority: TaskPriority = .normal, category: TaskCategory = .other) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = false
        self.priority = priority
        self.category = category
        self.sortOrder = 0
        self.createdAt = Date()
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
