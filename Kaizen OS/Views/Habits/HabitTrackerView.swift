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
    @State private var showTemplates = false
    @State private var hapticTrigger = 0
    @State private var viewingDate = Calendar.current.startOfDay(for: Date())

    // Pre-fill state for templates → AddHabitView flow
    @State private var prefillName = ""
    @State private var prefillEmoji = "✅"
    @State private var pendingTemplate = false

    private var isViewingToday: Bool {
        Calendar.current.isDateInToday(viewingDate)
    }

    private var viewingDateLabel: String {
        if isViewingToday { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: viewingDate)
    }

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

                    // Date navigation row
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewingDate = Calendar.current.date(byAdding: .day, value: -1, to: viewingDate) ?? viewingDate
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text(viewingDateLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            if !isViewingToday {
                                Text("Tap habits to edit history")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.kaizenOrange)
                            }
                        }

                        Spacer()

                        Button {
                            guard !isViewingToday else { return }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewingDate = Calendar.current.date(byAdding: .day, value: 1, to: viewingDate) ?? viewingDate
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isViewingToday ? Color.textTertiary : Color.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(isViewingToday ? 0.02 : 0.06))
                                .clipShape(Circle())
                        }
                        .disabled(isViewingToday)
                    }
                    .padding(.horizontal, 4)

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
                            HabitRowView(habit: habit, date: viewingDate) {
                                toggleHabit(habit)
                            }
                        }

                        // Analysis section
                        HabitAnalysisView(habits: habits)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.bgPrimary)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: hapticTrigger)
            .onAppear { autoArchiveExpiredHabits() }

            // Bottom actions: Templates pill + FAB
            HStack(spacing: 12) {
                Button {
                    showTemplates = true
                } label: {
                    Label("Templates", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(Color.bgElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.borderDefault, lineWidth: 1))
                }

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
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddHabit, onDismiss: {
            prefillName = ""
            prefillEmoji = "✅"
            pendingTemplate = false
        }) {
            AddHabitView(prefillName: prefillName, prefillEmoji: prefillEmoji)
        }
        .sheet(isPresented: $showTemplates, onDismiss: {
            if pendingTemplate {
                showAddHabit = true
            }
        }) {
            HabitTemplateView { name, emoji in
                prefillName = name
                prefillEmoji = emoji
                pendingTemplate = true
                showTemplates = false
            }
        }
    }

    // MARK: - Auto-archive habits past their end date

    private func autoArchiveExpiredHabits() {
        let today = Calendar.current.startOfDay(for: Date())
        for habit in habits where habit.isActive {
            if let end = habit.endDate, Calendar.current.startOfDay(for: end) < today {
                habit.isActive = false
            }
        }
        try? modelContext.save()
    }

    // MARK: - Toggle for viewingDate (supports past date editing)
    private func toggleHabit(_ habit: Habit) {
        hapticTrigger += 1
        let day = Calendar.current.startOfDay(for: viewingDate)
        if let existing = habit.entries.first(where: {
            Calendar.current.startOfDay(for: $0.date) == day
        }) {
            existing.isCompleted ? existing.uncomplete() : existing.complete()
        } else {
            let entry = HabitEntry(date: day, habit: habit)
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
