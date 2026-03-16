//
//  AddHabitView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { $0.isActive }) private var activeHabits: [Habit]
    @Query private var profiles: [UserProfile]

    @State private var name: String
    @State private var emoji: String
    @State private var enableReminder = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var reminderDays: Set<Int> = []
    @State private var showPaywall = false

    private var profile: UserProfile? { profiles.first }

    private let emojiOptions = ["✅", "⏰", "💪", "🧠", "🎧", "📵", "💰", "📚", "🏃", "💧", "🧘", "✍️", "🥗", "😴", "🎯"]
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    // MARK: - Init (supports optional pre-fill from templates)

    init(prefillName: String = "", prefillEmoji: String = "✅") {
        _name = State(initialValue: prefillName)
        _emoji = State(initialValue: prefillEmoji)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Emoji picker
                        VStack(spacing: 12) {
                            Text("Choose an icon")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.textSecondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                ForEach(emojiOptions, id: \.self) { option in
                                    Button {
                                        emoji = option
                                    } label: {
                                        Text(option)
                                            .font(.system(size: 28))
                                            .frame(width: 52, height: 52)
                                            .background(emoji == option ? Color.kaizenTeal.opacity(0.2) : Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(emoji == option ? Color.kaizenTeal : .clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.borderDefault, lineWidth: 1)
                        )

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

                        // Reminder section
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.kaizenTeal)
                                    .frame(width: 22)
                                Text("Daily Reminder")
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

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Repeat")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.textSecondary)

                                    HStack(spacing: 8) {
                                        ForEach(0..<7, id: \.self) { day in
                                            let isSelected = reminderDays.contains(day)
                                            Button {
                                                if isSelected { reminderDays.remove(day) } else { reminderDays.insert(day) }
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

                                    Text(reminderDays.isEmpty ? "Every day" : "\(reminderDays.count) day\(reminderDays.count == 1 ? "" : "s") selected")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
                        .animation(.easeInOut(duration: 0.2), value: enableReminder)

                        // Save button
                        Button { saveHabit() } label: {
                            Text("Add Habit")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(name.isEmpty ? Color.kaizenTeal.opacity(0.3) : Color.kaizenTeal)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Habit")
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

    private func saveHabit() {
        if profile?.isPremium != true && activeHabits.count >= UserProfile.freeHabitLimit {
            showPaywall = true
            return
        }

        let habit = Habit(name: name, emoji: emoji, sortOrder: activeHabits.count)

        if enableReminder {
            habit.reminderTime = reminderTime
            habit.reminderDays = Array(reminderDays).sorted()
            Task {
                await NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.scheduleHabitReminder(
                    habitName: habit.name,
                    emoji: habit.emoji,
                    time: reminderTime,
                    weekdays: Array(reminderDays).sorted(),
                    habitID: habit.id.uuidString
                )
            }
        }

        modelContext.insert(habit)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitEntry.self, UserProfile.self], inMemory: true)
}
