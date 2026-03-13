//
//  ContentView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @State private var selectedTab = 0

    private var profile: UserProfile? { profiles.first }

    private var showOnboarding: Bool {
        profile?.onboardingCompleted != true
    }

    var body: some View {
        if showOnboarding {
            OnboardingView()
        } else {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: 0) {
                    DashboardView()
                }

                Tab("Habits", systemImage: "checkmark.circle.fill", value: 1) {
                    HabitTrackerView()
                }

                Tab("Tasks", systemImage: "list.bullet", value: 2) {
                    TaskListView()
                }

                Tab("Mindset", systemImage: "waveform.path", value: 3) {
                    MindsetView()
                }

                Tab("Settings", systemImage: "gearshape.fill", value: 4) {
                    SettingsView()
                }
            }
            .tint(.kaizenTeal)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Habit.self,
            HabitEntry.self,
            DailyTask.self,
            MindsetLog.self,
            UserProfile.self
        ], inMemory: true)
}
