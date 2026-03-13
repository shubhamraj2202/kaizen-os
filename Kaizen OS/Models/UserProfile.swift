//
//  UserProfile.swift
//  Kaizen OS
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var isPremium: Bool
    var premiumPurchaseDate: Date?
    var onboardingCompleted: Bool
    var createdAt: Date
    var weekStartsOnMonday: Bool
    var dailyReminderEnabled: Bool
    var dailyReminderTime: Date?

    init(name: String = "") {
        self.id = UUID()
        self.name = name
        self.isPremium = false
        self.onboardingCompleted = false
        self.createdAt = Date()
        self.weekStartsOnMonday = true
        self.dailyReminderEnabled = false
    }

    static let freeHabitLimit = 5
}
