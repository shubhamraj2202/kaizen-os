//
//  DashboardView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Habit> { $0.isActive },
           sort: \Habit.sortOrder)
    private var habits: [Habit]

    @Query private var mindsetLogs: [MindsetLog]

    @State private var hapticTrigger = 0

    private var todayNote: String? {
        let today = Calendar.current.startOfDay(for: Date())
        return mindsetLogs.first {
            Calendar.current.startOfDay(for: $0.date) == today
        }?.note
    }

    // MARK: - Note save

    private func saveNote(_ text: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = mindsetLogs.first(where: { Calendar.current.startOfDay(for: $0.date) == today }) {
            existing.note = trimmed.isEmpty ? nil : trimmed
        } else {
            let log = MindsetLog(date: Date(), energy: 50, focus: 50, mood: 50)
            log.note = trimmed.isEmpty ? nil : trimmed
            modelContext.insert(log)
        }
        try? modelContext.save()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Date().displayDate)
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary)
                        Text("改善 Kaizen OS")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.kaizenTeal, .kaizenPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text("K")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(.black)
                        )
                }
                .padding(.top, 8)

                // Day Score
                DayScoreCard(habits: habits)

                // Stats row
                HStack(spacing: 10) {
                    StatCard(icon: "🔥", value: "\(bestStreak)d", label: "Best Streak", color: .kaizenOrange)
                    StatCard(icon: "📊", value: "\(weekPercent)%", label: "This Week", color: .kaizenTeal)
                    StatCard(icon: "⚡", value: "\(totalWins)", label: "Total Wins", color: .kaizenPurple)
                }

                // Today's Note card — inline editable
                TodayNoteCard(savedNote: todayNote, onSave: saveNote)

                // Today's Habits preview
                VStack(spacing: 8) {
                    HStack {
                        Text("Today's Habits")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        // FIX: was plain Text, now a real Button
                        Button {
                            selectedTab = 1
                        } label: {
                            Text("See all →")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.kaizenTeal)
                        }
                    }

                    if habits.isEmpty {
                        Text("No habits yet — tap Habits to add your first one.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(habits.prefix(4)) { habit in
                            // FIX: now passes a real toggle action
                            HabitPreviewRow(habit: habit) {
                                toggleHabit(habit)
                            }
                        }
                    }
                }

                // Mindset CTA — FIX: now passes action to "Log now"
                MindsetCTABanner {
                    selectedTab = 3
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.bgPrimary)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: hapticTrigger)
    }

    // MARK: - Computed Stats

    private var bestStreak: Int {
        habits.map(\.longestStreak).max() ?? 0
    }

    private var weekPercent: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else { return 0 }
        guard !habits.isEmpty else { return 0 }
        var total = 0
        var completed = 0
        for habit in habits {
            for dayOffset in 0...6 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                total += 1
                if habit.isCompleted(on: date) { completed += 1 }
            }
        }
        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    private var totalWins: Int {
        habits.flatMap(\.entries).filter(\.isCompleted).count
    }

    // MARK: - Actions

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

// MARK: - Day Score Card

private struct DayScoreCard: View {
    let habits: [Habit]

    private var donePct: Int {
        guard !habits.isEmpty else { return 0 }
        let done = habits.filter { $0.isCompleted(on: Date()) }.count
        return Int(Double(done) / Double(habits.count) * 100)
    }

    private var doneCount: Int {
        habits.filter { $0.isCompleted(on: Date()) }.count
    }

    var body: some View {
        HStack(spacing: 20) {
            DayScoreRingView(percent: donePct, size: 90, strokeWidth: 9)

            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY'S SCORE")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                    .tracking(0.8)
                Text("\(donePct)%")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    TagPill(
                        text: "🔥 \(doneCount)/\(habits.count) habits",
                        bgColor: .kaizenTeal.opacity(0.15),
                        textColor: .kaizenTeal
                    )
                }
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.kaizenTeal.opacity(0.15), .kaizenPurple.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.kaizenTeal.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.borderDefault, lineWidth: 1)
        )
    }
}

// MARK: - Habit Preview Row
// FIX: Added onToggle closure so tapping actually toggles the habit

private struct HabitPreviewRow: View {
    let habit: Habit
    let onToggle: () -> Void

    private var isCompleted: Bool { habit.isCompleted(on: Date()) }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Text(habit.emoji)
                    .font(.system(size: 18))
                Text(habit.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCompleted ? Color.kaizenTeal : .clear)
                        .frame(width: 22, height: 22)
                    if !isCompleted {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.black)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Pill

private struct TagPill: View {
    let text: String
    let bgColor: Color
    let textColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(bgColor)
            .clipShape(Capsule())
    }
}

// MARK: - Today's Note Card (inline editable)

private struct TodayNoteCard: View {
    let savedNote: String?
    let onSave: (String) -> Void

    @State private var text: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundColor(Color.kaizenOrange)
                Text("TODAY'S NOTE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.kaizenOrange.opacity(0.7))
                    .tracking(0.6)
                Spacer()
                if isEditing {
                    Button("Done") {
                        focused = false
                        isEditing = false
                        onSave(text)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.kaizenOrange)
                } else {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textTertiary)
                }
            }

            // Body
            if isEditing {
                TextField("Brain dump, reminders, anything on your mind…", text: $text, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(3...8)
                    .tint(Color.kaizenOrange)
                    .focused($focused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                focused = false
                                isEditing = false
                                onSave(text)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.kaizenOrange)
                        }
                    }
            } else {
                if let note = savedNote, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Tap to add a note for today…")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
        .padding(16)
        .background(Color.kaizenOrange.opacity(isEditing ? 0.09 : 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.kaizenOrange.opacity(isEditing ? 0.35 : (savedNote != nil ? 0.2 : 0.08)), lineWidth: 1)
        )
        .onTapGesture {
            guard !isEditing else { return }
            text = savedNote ?? ""
            isEditing = true
            focused = true
        }
        .onChange(of: savedNote) { _, new in
            if !isEditing { text = new ?? "" }
        }
    }
}

// MARK: - Mindset CTA Banner
// FIX: Added onLogNow closure so "Log now" actually navigates to Mindset tab

private struct MindsetCTABanner: View {
    let onLogNow: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("🧘")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text("Mindset Check-in")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text("How's your energy today?")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
            Button(action: onLogNow) {
                Text("Log now")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.kaizenPurple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.kaizenPurple.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.kaizenPurple.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView(selectedTab: .constant(0))
        .modelContainer(for: [Habit.self, HabitEntry.self, DailyTask.self, MindsetLog.self, UserProfile.self], inMemory: true)
}
