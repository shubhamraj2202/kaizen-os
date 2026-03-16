//
//  MindsetLog.swift
//  Kaizen OS
//

import Foundation
import SwiftData

@Model
final class MindsetLog {
    var id: UUID
    var date: Date
    var energy: Int
    var focus: Int
    var mood: Int
    var note: String?

    // MARK: - Health fields (manual or HealthKit-imported)
    var sleepHours: Double?   // 0.0–12.0
    var wakeTime: Date?       // hour + minute only (full Date stored, only time components used)
    var stepsManual: Int?     // manually entered or imported from HealthKit

    var createdAt: Date

    init(date: Date = Date(), energy: Int = 50, focus: Int = 50, mood: Int = 50) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.energy = energy
        self.focus = focus
        self.mood = mood
        self.createdAt = Date()
    }

    var overallScore: Int { (energy + focus + mood) / 3 }
}
