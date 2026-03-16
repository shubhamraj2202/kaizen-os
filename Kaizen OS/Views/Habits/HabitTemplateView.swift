//
//  HabitTemplateView.swift
//  Kaizen OS
//

import SwiftUI

struct HabitTemplate: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
}

private let templateCategories: [(title: String, items: [HabitTemplate])] = [
    ("Health", [
        HabitTemplate(name: "Drink Water", emoji: "💧"),
        HabitTemplate(name: "Sleep 8hrs", emoji: "😴"),
        HabitTemplate(name: "Eat Healthy", emoji: "🥗"),
        HabitTemplate(name: "Walk 30min", emoji: "🚶"),
        HabitTemplate(name: "No Alcohol", emoji: "🚫"),
    ]),
    ("Fitness", [
        HabitTemplate(name: "Workout", emoji: "💪"),
        HabitTemplate(name: "Run", emoji: "🏃"),
        HabitTemplate(name: "Stretch", emoji: "🧘"),
        HabitTemplate(name: "Cycle", emoji: "🚴"),
    ]),
    ("Mind", [
        HabitTemplate(name: "Meditate", emoji: "🧠"),
        HabitTemplate(name: "Read 20min", emoji: "📚"),
        HabitTemplate(name: "Journal", emoji: "✍️"),
        HabitTemplate(name: "Gratitude", emoji: "🙏"),
    ]),
    ("Focus", [
        HabitTemplate(name: "No Phone AM", emoji: "📵"),
        HabitTemplate(name: "Wake Early", emoji: "⏰"),
        HabitTemplate(name: "Deep Work", emoji: "🎯"),
        HabitTemplate(name: "Plan Your Day", emoji: "📋"),
        HabitTemplate(name: "No Social Media", emoji: "🔕"),
    ]),
    ("Finance", [
        HabitTemplate(name: "Track Spending", emoji: "💰"),
        HabitTemplate(name: "Review Budget", emoji: "📈"),
        HabitTemplate(name: "Save Money", emoji: "🏦"),
    ]),
]

struct HabitTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String, String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Pick a template to get started — you can edit the name before saving.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)

                        ForEach(templateCategories, id: \.title) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.title.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color.textTertiary)
                                    .tracking(0.8)

                                VStack(spacing: 0) {
                                    ForEach(Array(category.items.enumerated()), id: \.element.id) { idx, template in
                                        Button {
                                            onSelect(template.name, template.emoji)
                                            dismiss()
                                        } label: {
                                            HStack(spacing: 14) {
                                                Text(template.emoji)
                                                    .font(.system(size: 22))
                                                    .frame(width: 36)
                                                Text(template.name)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundStyle(.white)
                                                Spacer()
                                                Image(systemName: "plus.circle")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(Color.kaizenTeal.opacity(0.7))
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 13)
                                        }
                                        .buttonStyle(.plain)

                                        if idx < category.items.count - 1 {
                                            Divider()
                                                .background(Color.borderDefault)
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.borderDefault, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Habit Templates")
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
