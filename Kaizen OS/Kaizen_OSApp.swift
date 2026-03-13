//
//  Kaizen_OSApp.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

@main
struct Kaizen_OSApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                Habit.self,
                HabitEntry.self,
                DailyTask.self,
                MindsetLog.self,
                UserProfile.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
