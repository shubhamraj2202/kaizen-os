//
//  HabitTrackerView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct HabitTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query(filter: #Predicate<Habit> { !$0.isActive }, sort: \Habit.sortOrder)
    private var retiredHabits: [Habit]

    @State private var showAddHabit = false
    @State private var showTemplates = false
    @State private var editingHabit: Habit? = nil
    @State private var hapticTrigger = 0
    @State private var viewingDate = Calendar.current.startOfDay(for: Date())

    // Pause sheet
    @State private var pausingHabit: Habit? = nil
    @State private var pauseUntilDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // Delete confirm
    @State private var deletingHabit: Habit? = nil

    // Retired section toggle
    @State private var showRetired = false

    // Pre-fill state for templates → AddHabitView flow
    @State private var prefillName = ""
    @State private var prefillEmoji = "✅"
    @State private var pendingTemplate = false

    private let cal = Calendar.current

    private var activeHabitsForDate: [Habit] {
        let weekday = cal.component(.weekday, from: viewingDate) - 1
        return habits.filter { habit in
            guard habit.isActive else { return false }
            return habit.scheduledWeekdays.isEmpty || habit.scheduledWeekdays.contains(weekday)
        }
    }

    private var isViewingToday: Bool { cal.isDateInToday(viewingDate) }

    private var viewingDateLabel: String {
        if isViewingToday { return "Today" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
        return f.string(from: viewingDate)
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
                                viewingDate = cal.date(byAdding: .day, value: -1, to: viewingDate) ?? viewingDate
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
                                viewingDate = cal.date(byAdding: .day, value: 1, to: viewingDate) ?? viewingDate
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

                    // Active habit rows
                    if activeHabitsForDate.isEmpty {
                        VStack(spacing: 12) {
                            if habits.filter(\.isActive).isEmpty {
                                Text("🌱").font(.system(size: 48))
                                Text("No habits yet")
                                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                                Text("Tap + to add your first habit")
                                    .font(.system(size: 14)).foregroundColor(Color.textTertiary)
                            } else {
                                Text("😌").font(.system(size: 48))
                                Text("Rest day")
                                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                                Text("No habits scheduled for this day")
                                    .font(.system(size: 14)).foregroundColor(Color.textTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(activeHabitsForDate) { habit in
                            HabitRowView(habit: habit, date: viewingDate) {
                                toggleHabit(habit)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button { editingHabit = habit } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.kaizenTeal)

                                Button(role: .destructive) {
                                    retireHabit(habit)
                                } label: {
                                    Label("Retire", systemImage: "archivebox")
                                }
                            }
                            .contextMenu {
                                // Edit
                                Button { editingHabit = habit } label: {
                                    Label("Edit Habit", systemImage: "pencil")
                                }

                                Divider()

                                // Skip Today (only when viewing today and not already paused)
                                if isViewingToday && !habit.isPaused {
                                    let alreadySkipped = isSkipped(habit, on: viewingDate)
                                    Button {
                                        skipToday(habit)
                                    } label: {
                                        Label(alreadySkipped ? "Undo Skip" : "Skip Today",
                                              systemImage: alreadySkipped ? "arrow.uturn.backward" : "forward.fill")
                                    }
                                }

                                // Pause / Resume
                                if habit.isPaused {
                                    Button {
                                        resumeHabit(habit)
                                    } label: {
                                        Label("Resume Now", systemImage: "play.fill")
                                    }
                                } else {
                                    Button {
                                        pauseUntilDate = cal.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                                        pausingHabit = habit
                                    } label: {
                                        Label("Pause…", systemImage: "pause.fill")
                                    }
                                }

                                Divider()

                                // Retire
                                Button {
                                    retireHabit(habit)
                                } label: {
                                    Label("Retire Habit", systemImage: "archivebox")
                                }

                                // Delete (destructive)
                                Button(role: .destructive) {
                                    deletingHabit = habit
                                } label: {
                                    Label("Delete & Erase History", systemImage: "trash")
                                }
                            }
                        }

                        // Analysis section
                        HabitAnalysisView(habits: habits)
                    }

                    // Retired habits section
                    if !retiredHabits.isEmpty {
                        retiredSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color.bgPrimary)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: hapticTrigger)
            .onAppear { autoManageHabits() }

            // Bottom actions: Templates pill + FAB
            HStack(spacing: 12) {
                Button { showTemplates = true } label: {
                    Label("Templates", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(Color.bgElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.borderDefault, lineWidth: 1))
                }

                Button { showAddHabit = true } label: {
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
        // Edit sheet
        .sheet(item: $editingHabit) { habit in
            AddHabitView(editing: habit)
        }
        // Add habit sheet
        .sheet(isPresented: $showAddHabit, onDismiss: {
            prefillName = ""; prefillEmoji = "✅"; pendingTemplate = false
        }) {
            AddHabitView(prefillName: prefillName, prefillEmoji: prefillEmoji)
        }
        // Templates sheet
        .sheet(isPresented: $showTemplates, onDismiss: {
            if pendingTemplate { showAddHabit = true }
        }) {
            HabitTemplateView { name, emoji in
                prefillName = name; prefillEmoji = emoji
                pendingTemplate = true; showTemplates = false
            }
        }
        // Pause sheet
        .sheet(item: $pausingHabit) { habit in
            PauseHabitSheet(habit: habit, pauseUntil: $pauseUntilDate) {
                pauseHabit(habit, until: pauseUntilDate)
            }
        }
        // Delete confirmation
        .alert("Delete Habit?", isPresented: Binding(
            get: { deletingHabit != nil },
            set: { if !$0 { deletingHabit = nil } }
        )) {
            Button("Delete & Erase History", role: .destructive) {
                if let h = deletingHabit { deleteHabit(h) }
            }
            Button("Cancel", role: .cancel) { deletingHabit = nil }
        } message: {
            Text("This permanently deletes the habit and all its history. This cannot be undone.")
        }
    }

    // MARK: - Retired Section

    private var retiredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showRetired.toggle() }
            } label: {
                HStack {
                    Image(systemName: showRetired ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.textTertiary)
                    Text("RETIRED (\(retiredHabits.count))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.textTertiary)
                        .tracking(0.8)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if showRetired {
                ForEach(retiredHabits) { habit in
                    HStack(spacing: 12) {
                        Text(habit.emoji)
                            .font(.system(size: 18))
                            .opacity(0.5)
                        Text(habit.name)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        // Restore
                        Button {
                            habit.isActive = true
                            try? modelContext.save()
                        } label: {
                            Text("Restore")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.kaizenTeal)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.kaizenTeal.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        // Delete
                        Button {
                            deletingHabit = habit
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textTertiary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
    }

    // MARK: - Actions

    private func toggleHabit(_ habit: Habit) {
        hapticTrigger += 1
        let day = cal.startOfDay(for: viewingDate)
        if let existing = habit.entries.first(where: { cal.startOfDay(for: $0.date) == day }) {
            if existing.isSkipped {
                existing.complete()  // skipped → tapping completes it
            } else {
                existing.isCompleted ? existing.uncomplete() : existing.complete()
            }
        } else {
            let entry = HabitEntry(date: day, habit: habit)
            entry.complete()
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    private func skipToday(_ habit: Habit) {
        hapticTrigger += 1
        let day = cal.startOfDay(for: viewingDate)
        if let existing = habit.entries.first(where: { cal.startOfDay(for: $0.date) == day }) {
            if existing.isSkipped {
                modelContext.delete(existing)  // undo skip
            } else if !existing.isCompleted {
                existing.skip()
            }
            // Already completed — don't skip
        } else {
            let entry = HabitEntry(date: day, habit: habit)
            entry.skip()
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    private func pauseHabit(_ habit: Habit, until date: Date) {
        let endDay = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: Date())
        // Create skipped entries for scheduled days from today → endDay
        var checkDate = today
        while checkDate <= endDay {
            if habit.isScheduled(on: checkDate) {
                if let existing = habit.entries.first(where: { cal.startOfDay(for: $0.date) == checkDate }) {
                    if !existing.isCompleted { existing.skip() }
                } else {
                    let entry = HabitEntry(date: checkDate, habit: habit)
                    entry.skip()
                    modelContext.insert(entry)
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = next
        }
        habit.pausedUntil = endDay
        try? modelContext.save()
    }

    private func resumeHabit(_ habit: Habit) {
        let today = cal.startOfDay(for: Date())
        // Remove future skipped entries (today onwards)
        let toRemove = habit.entries.filter {
            cal.startOfDay(for: $0.date) >= today && $0.isSkipped
        }
        for entry in toRemove { modelContext.delete(entry) }
        habit.pausedUntil = nil
        try? modelContext.save()
    }

    private func retireHabit(_ habit: Habit) {
        habit.isActive = false
        habit.pausedUntil = nil
        try? modelContext.save()
    }

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)  // cascade deletes all HabitEntry records
        try? modelContext.save()
        deletingHabit = nil
    }

    private func isSkipped(_ habit: Habit, on date: Date) -> Bool {
        let day = cal.startOfDay(for: date)
        return habit.entries.contains { cal.startOfDay(for: $0.date) == day && $0.isSkipped }
    }

    // MARK: - Auto-manage on appear

    private func autoManageHabits() {
        let today = cal.startOfDay(for: Date())
        for habit in habits where habit.isActive {
            // Auto-retire past end date
            if let end = habit.endDate, cal.startOfDay(for: end) < today {
                habit.isActive = false
            }
            // Auto-resume past pause date
            if let until = habit.pausedUntil, cal.startOfDay(for: until) < today {
                habit.pausedUntil = nil
            }
        }
        try? modelContext.save()
    }
}

// MARK: - Pause Sheet

private struct PauseHabitSheet: View {
    let habit: Habit
    @Binding var pauseUntil: Date
    let onPause: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var minDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Habit preview
                    HStack(spacing: 12) {
                        Text(habit.emoji).font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Will resume automatically")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resume on")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        DatePicker("", selection: $pauseUntil, in: minDate..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Color.kaizenPurple)
                            .colorScheme(.dark)
                            .labelsHidden()
                    }

                    Spacer()

                    Button {
                        onPause()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.fill")
                            Text("Pause until \(pauseUntil.formatted(date: .abbreviated, time: .omitted))")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.kaizenPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Pause Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.textSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    HabitTrackerView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
