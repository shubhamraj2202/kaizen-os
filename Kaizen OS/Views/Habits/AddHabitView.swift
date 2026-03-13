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

    @State private var name = ""
    @State private var emoji = "✅"
    @State private var showPaywall = false

    private var profile: UserProfile? { profiles.first }

    private let emojiOptions = ["✅", "⏰", "💪", "🧠", "🎧", "📵", "💰", "📚", "🏃", "💧", "🧘", "✍️", "🥗", "😴", "🎯"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
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

                    Spacer()

                    // Save button
                    Button {
                        saveHabit()
                    } label: {
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
                .padding(.bottom, 16)
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func saveHabit() {
        // Check free tier limit
        if profile?.isPremium != true && activeHabits.count >= UserProfile.freeHabitLimit {
            showPaywall = true
            return
        }

        let habit = Habit(name: name, emoji: emoji, sortOrder: activeHabits.count)
        modelContext.insert(habit)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitEntry.self, UserProfile.self], inMemory: true)
}
