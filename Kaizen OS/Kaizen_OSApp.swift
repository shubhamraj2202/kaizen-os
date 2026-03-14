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
            // Use App Group container so the widget extension can read the same store.
            // Requires "App Groups" capability → group.com.shubh.kaizenos on BOTH targets.
            // If the App Group is not yet configured, falls back to the default store.
            let appGroupID = "group.com.shubh.kaizenos"
            if let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupID
            ) {
                let storeURL = groupURL.appendingPathComponent("kaizen.store")
                let config = ModelConfiguration(url: storeURL)
                container = try ModelContainer(
                    for: Habit.self, HabitEntry.self, DailyTask.self, MindsetLog.self, UserProfile.self,
                    configurations: config
                )
            } else {
                // Fallback: App Groups not yet configured — uses default container location
                container = try ModelContainer(
                    for: Habit.self, HabitEntry.self, DailyTask.self, MindsetLog.self, UserProfile.self
                )
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
        }
    }
}
