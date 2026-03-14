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
            // iOS 17-compatible TabView syntax (.tabItem + .tag)
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Home", image: "TabIcon-Dashboard")
                    }
                    .tag(0)

                HabitTrackerView()
                    .tabItem {
                        Label("Habits", image: "TabIcon-Habits")
                    }
                    .tag(1)

                TaskListView()
                    .tabItem {
                        Label("Tasks", image: "TabIcon-Tasks")
                    }
                    .tag(2)

                MindsetView()
                    .tabItem {
                        Label("Mindset", image: "TabIcon-Mindset")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Settings", image: "TabIcon-Settings")
                    }
                    .tag(4)
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
