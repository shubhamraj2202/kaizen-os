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

                    // Habit rows
                    ForEach(habits.filter(\.isActive)) { habit in
                        HabitRowView(habit: habit) {
                            toggleHabit(habit)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .background(Color.bgPrimary)

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

    private func toggleHabit(_ habit: Habit) {
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
