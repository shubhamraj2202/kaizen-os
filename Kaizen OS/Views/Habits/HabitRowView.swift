//
//  HabitRowView.swift
//  Kaizen OS
//

import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    private var isCompleted: Bool { habit.isCompleted(on: Date()) }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Emoji icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isCompleted ? Color.kaizenTeal.opacity(0.15) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                    Text(habit.emoji)
                        .font(.system(size: 20))
                }

                // Name & streak
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("🔥 \(habit.currentStreak) day streak")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textTertiary)
                }

                Spacer()

                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isCompleted ? Color.kaizenTeal : .clear)
                        .frame(width: 28, height: 28)
                        .shadow(color: isCompleted ? .kaizenTeal.opacity(0.5) : .clear, radius: 12)
                    if !isCompleted {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isCompleted ? Color.kaizenTeal.opacity(0.25) : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let habit = Habit(name: "Early Start", emoji: "⏰", colorHex: "#00E5C8")
    return HabitRowView(habit: habit, onToggle: {})
        .background(Color.bgPrimary)
}
