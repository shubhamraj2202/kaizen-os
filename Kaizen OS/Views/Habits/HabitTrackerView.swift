//
//  HabitTrackerView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct HabitTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showAddHabit = false
    @State private var hapticTrigger = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Date().monthYear)
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary)
                        Text("Habit Tracker")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    // Heatmap
                    HeatmapView(habits: habits)

                    // Habit rows or empty state
                    if habits.filter(\.isActive).isEmpty {
                        VStack(spacing: 12) {
                            Text("🌱")
                                .font(.system(size: 48))
                            Text("No habits yet")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Tap + to add your first habit")
                                .font(.system(size: 14))
                                .foregroundColor(Color.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(habits.filter(\.isActive)) { habit in
                            HabitRowView(habit: habit) {
                                toggleHabit(habit)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .background(Color.bgPrimary)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: hapticTrigger)

            // FAB
            Button {
                showAddHabit = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 56)
                    .background(Color.kaizenTeal)
                    .clipShape(Circle())
                    .shadow(color: .kaizenTeal.opacity(0.4), radius: 16)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitView()
        }
    }

    // MARK: - Toggle with haptic feedback
    private func toggleHabit(_ habit: Habit) {
        hapticTrigger += 1
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = habit.entries.first(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            existing.isCompleted ? existing.uncomplete() : existing.complete()
        } else {
            let entry = HabitEntry(date: today, habit: habit)
            entry.complete()
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

#Preview {
    HabitTrackerView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
