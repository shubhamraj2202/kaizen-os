//
//  AddHabitView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

// MARK: - Duration Option

private enum DurationOption: Equatable, CaseIterable, Hashable {
    case forever, days21, days90, year1, custom

    var label: String {
        switch self {
        case .forever: return "Forever"
        case .days21:  return "21 days"
        case .days90:  return "90 days"
        case .year1:   return "1 year"
        case .custom:  return "Custom"
        }
    }

    // Computes the end date from today for preset options
    var computedEndDate: Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        switch self {
        case .forever: return nil
        case .days21:  return cal.date(byAdding: .day, value: 21, to: today)
        case .days90:  return cal.date(byAdding: .day, value: 90, to: today)
        case .year1:   return cal.date(byAdding: .year, value: 1, to: today)
        case .custom:  return nil
        }
    }
}

// MARK: - AddHabitView

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { $0.isActive }) private var activeHabits: [Habit]
    @Query private var profiles: [UserProfile]

    @State private var name: String
    @State private var emoji: String
    @State private var customEmojiText = ""

    // Reminder
    @State private var enableReminder = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var reminderLeadMinutes: Set<Int> = [0]  // multi-select, default = at time

    // Schedule
    @State private var scheduleAllDays = true
    @State private var habitScheduledDays: Set<Int> = []

    // Duration
    @State private var durationOption: DurationOption = .forever
    @State private var customEndDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    @State private var showPaywall = false

    private var editingHabit: Habit?   // non-nil = edit mode
    private var profile: UserProfile? { profiles.first }

    private let emojiOptions = ["✅", "⏰", "💪", "🧠", "🎧", "📵", "💰", "📚", "🏃", "💧", "🧘", "✍️", "🥗", "😴", "🎯"]
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let leadOptions: [(label: String, minutes: Int)] = [
        ("At time", 0), ("5 min before", 5), ("10 min before", 10),
        ("15 min before", 15), ("30 min before", 30)
    ]

    // MARK: - Init

    // New habit (optionally pre-filled from a template)
    init(prefillName: String = "", prefillEmoji: String = "✅") {
        _name = State(initialValue: prefillName)
        _emoji = State(initialValue: prefillEmoji)
    }

    // Edit existing habit — pre-populates all fields
    init(editing habit: Habit) {
        editingHabit = habit
        _name = State(initialValue: habit.name)
        _emoji = State(initialValue: habit.emoji)
        _enableReminder = State(initialValue: habit.reminderTime != nil)
        _reminderTime = State(initialValue: habit.reminderTime ?? (Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()))
        _reminderLeadMinutes = State(initialValue: habit.reminderLeadMinutesList.isEmpty ? [0] : Set(habit.reminderLeadMinutesList))
        _scheduleAllDays = State(initialValue: habit.scheduledWeekdays.isEmpty)
        _habitScheduledDays = State(initialValue: Set(habit.scheduledWeekdays))
        if let end = habit.endDate {
            _durationOption = State(initialValue: .custom)
            _customEndDate = State(initialValue: end)
        } else {
            _durationOption = State(initialValue: .forever)
            _customEndDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        emojiSection

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habit name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                            TextField("e.g. Morning Workout", text: $name)
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.borderDefault, lineWidth: 1)
                                )
                        }

                        durationSection
                        scheduleSection
                        reminderSection

                        // Save button
                        Button { saveHabit() } label: {
                            Text(editingHabit == nil ? "Add Habit" : "Save Changes")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(name.isEmpty ? Color.kaizenTeal.opacity(0.3) : Color.kaizenTeal)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(name.isEmpty || (!scheduleAllDays && habitScheduledDays.isEmpty))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(editingHabit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.textSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Emoji Section

    private var emojiSection: some View {
        VStack(spacing: 12) {
            Text("Choose an icon")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(emojiOptions, id: \.self) { option in
                    Button {
                        emoji = option
                        customEmojiText = ""
                    } label: {
                        let isSelected = emoji == option && customEmojiText.isEmpty
                        Text(option)
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(isSelected ? Color.kaizenTeal.opacity(0.2) : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.kaizenTeal : .clear, lineWidth: 2)
                            )
                    }
                }
            }

            // Custom emoji input — user types from native emoji keyboard
            HStack(spacing: 10) {
                Text("Or type any emoji →")
                    .font(.system(size: 13))
                    .foregroundColor(Color.textTertiary)
                Spacer()
                TextField("✨", text: $customEmojiText)
                    .font(.system(size: 26))
                    .multilineTextAlignment(.center)
                    .frame(width: 52, height: 44)
                    .background(customEmojiText.isEmpty ? Color.white.opacity(0.06) : Color.kaizenTeal.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(customEmojiText.isEmpty ? Color.borderDefault : Color.kaizenTeal, lineWidth: 2)
                    )
                    .onChange(of: customEmojiText) { _, new in
                        guard !new.isEmpty else { return }
                        // Keep last typed emoji (emoji can be multi-scalar, max 2 chars)
                        let trimmed = String(new.suffix(2))
                        if trimmed != new { customEmojiText = trimmed }
                        emoji = trimmed
                    }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.borderDefault, lineWidth: 1))
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DurationOption.allCases, id: \.self) { option in
                        Button { durationOption = option } label: {
                            Text(option.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(durationOption == option ? .white : Color.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(durationOption == option ? Color.kaizenTeal.opacity(0.2) : Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(durationOption == option ? Color.kaizenTeal : .clear, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 1)
            }

            if durationOption == .custom {
                HStack {
                    Text("End date")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    DatePicker("", selection: $customEndDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(Color.kaizenTeal)
                        .colorScheme(.dark)
                        .labelsHidden()
                }
                .padding(.top, 4)
            }

            if durationOption != .forever {
                let endDate = durationOption == .custom
                    ? customEndDate
                    : (durationOption.computedEndDate ?? Date())
                Text("Auto-archives on \(endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textTertiary)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: durationOption)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textSecondary)

            HStack(spacing: 8) {
                ForEach([(true, "Every day"), (false, "Specific days")], id: \.0) { allDays, label in
                    Button { scheduleAllDays = allDays } label: {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(scheduleAllDays == allDays ? .white : Color.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(scheduleAllDays == allDays ? Color.kaizenTeal.opacity(0.2) : Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(scheduleAllDays == allDays ? Color.kaizenTeal : .clear, lineWidth: 1))
                    }
                }
                Spacer()
            }

            if !scheduleAllDays {
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        let isSelected = habitScheduledDays.contains(day)
                        Button {
                            if isSelected { habitScheduledDays.remove(day) } else { habitScheduledDays.insert(day) }
                        } label: {
                            Text(weekdayLabels[day])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSelected ? .black : Color.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(isSelected ? Color.kaizenTeal : Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                if habitScheduledDays.isEmpty {
                    Text("Select at least one day")
                        .font(.system(size: 12))
                        .foregroundColor(Color.kaizenOrange.opacity(0.8))
                } else {
                    Text("\(habitScheduledDays.count) day\(habitScheduledDays.count == 1 ? "" : "s") per week")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: scheduleAllDays)
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Color.kaizenTeal)
                    .frame(width: 22)
                Text("Reminder")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Toggle("", isOn: $enableReminder)
                    .tint(Color.kaizenTeal)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if enableReminder {
                Divider().background(Color.borderDefault).padding(.horizontal, 16)

                // Time picker
                HStack {
                    Text("Time")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .tint(Color.kaizenTeal)
                        .colorScheme(.dark)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().background(Color.borderDefault).padding(.horizontal, 16)

                // Lead time — "notify me X before"
                VStack(alignment: .leading, spacing: 10) {
                    Text("Notify me")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(leadOptions, id: \.minutes) { option in
                                Button {
                                    if reminderLeadMinutes.contains(option.minutes) {
                                        // Keep at least one selected
                                        if reminderLeadMinutes.count > 1 { reminderLeadMinutes.remove(option.minutes) }
                                    } else {
                                        reminderLeadMinutes.insert(option.minutes)
                                    }
                                } label: {
                                    let isSelected = reminderLeadMinutes.contains(option.minutes)
                                    Text(option.label)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : Color.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(isSelected ? Color.kaizenTeal.opacity(0.2) : Color.white.opacity(0.06))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(isSelected ? Color.kaizenTeal : .clear, lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)


                // Reminder fires on the same days as the habit schedule (auto-follows)
                let scheduleSummary: String = {
                    if scheduleAllDays { return "Every day" }
                    let count = habitScheduledDays.count
                    return count == 0 ? "No days selected" : "\(count) day\(count == 1 ? "" : "s") per week"
                }()
                HStack {
                    Text("Repeats")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    Text(scheduleSummary)
                        .font(.system(size: 13))
                        .foregroundColor(Color.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: enableReminder)
    }

    // MARK: - Save

    private func saveHabit() {
        let finalEmoji = customEmojiText.isEmpty ? emoji : customEmojiText

        if let existing = editingHabit {
            // --- Edit mode: mutate existing habit in-place ---
            existing.name = name
            existing.emoji = finalEmoji
            applyDuration(to: existing)
            applySchedule(to: existing)
            applyReminder(to: existing)
            try? modelContext.save()
            dismiss()
        } else {
            // --- Create mode: paywall check then insert ---
            if profile?.isPremium != true && activeHabits.count >= UserProfile.freeHabitLimit {
                showPaywall = true
                return
            }
            let habit = Habit(name: name, emoji: finalEmoji, sortOrder: activeHabits.count)
            applyDuration(to: habit)
            applySchedule(to: habit)
            applyReminder(to: habit)
            modelContext.insert(habit)
            try? modelContext.save()
            dismiss()
        }
    }

    private func applySchedule(to habit: Habit) {
        habit.scheduledWeekdays = scheduleAllDays ? [] : Array(habitScheduledDays).sorted()
    }

    private func applyDuration(to habit: Habit) {
        switch durationOption {
        case .forever: habit.endDate = nil
        case .custom:  habit.endDate = Calendar.current.startOfDay(for: customEndDate)
        default:       habit.endDate = durationOption.computedEndDate
        }
    }

    private func applyReminder(to habit: Habit) {
        if enableReminder {
            // Reminder fires on same days as the habit schedule ([] = every day)
            let scheduleDays = scheduleAllDays ? [] : Array(habitScheduledDays).sorted()
            habit.reminderTime = reminderTime
            habit.reminderDays = scheduleDays
            habit.reminderLeadMinutesList = Array(reminderLeadMinutes).sorted()
            Task {
                await NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.scheduleHabitReminder(
                    habitName: habit.name,
                    emoji: habit.emoji,
                    time: reminderTime,
                    weekdays: scheduleDays,
                    habitID: habit.id.uuidString,
                    leadMinutesList: Array(reminderLeadMinutes).sorted()
                )
            }
        } else {
            // Clear any previously scheduled notifications
            habit.reminderTime = nil
            habit.reminderDays = []
            habit.reminderLeadMinutesList = []
            NotificationManager.shared.removeHabitReminder(habitID: habit.id.uuidString)
        }
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitEntry.self, UserProfile.self], inMemory: true)
}
