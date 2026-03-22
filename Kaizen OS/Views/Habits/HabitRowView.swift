//
//  HabitRowView.swift
//  Kaizen OS
//

import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let date: Date          // which day to show completion for
    let onToggle: () -> Void

    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkippedToday: Bool {
        let day = Calendar.current.startOfDay(for: date)
        return habit.entries.contains { Calendar.current.startOfDay(for: $0.date) == day && $0.isSkipped }
    }

    var body: some View {
        Button(action: habit.isPaused ? {} : onToggle) {
            HStack(spacing: 14) {
                // Emoji icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(rowBgColor)
                        .frame(width: 44, height: 44)
                    Text(habit.emoji)
                        .font(.system(size: 20))
                        .opacity(habit.isPaused ? 0.4 : 1)
                }

                // Name & subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(habit.isPaused ? .white.opacity(0.4) : .white)
                    HStack(spacing: 6) {
                        if habit.isPaused, let until = habit.pausedUntil {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color.kaizenPurple)
                            Text("Paused until \(until.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 12))
                                .foregroundColor(Color.kaizenPurple.opacity(0.8))
                        } else if isSkippedToday {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color.kaizenOrange)
                            Text("Skipped today")
                                .font(.system(size: 12))
                                .foregroundColor(Color.kaizenOrange.opacity(0.8))
                        } else {
                            Text("🔥 \(habit.currentStreak) day streak")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textTertiary)
                            if habit.reminderTime != nil {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color.kaizenTeal.opacity(0.7))
                            }
                            if let badge = habit.durationBadge {
                                Text(badge)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(badge == "🎉 Done!" ? Color.kaizenOrange : Color.kaizenPurple.opacity(0.9))
                            }
                        }
                    }
                }

                Spacer()

                // Checkbox / state icon
                if habit.isPaused {
                    Image(systemName: "pause.circle")
                        .font(.system(size: 22))
                        .foregroundColor(Color.kaizenPurple.opacity(0.4))
                } else if isSkippedToday {
                    Image(systemName: "forward.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.kaizenOrange.opacity(0.6))
                } else {
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(habit.isPaused ? 0.02 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(rowBorderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var rowBgColor: Color {
        if habit.isPaused { return Color.white.opacity(0.03) }
        if isSkippedToday { return Color.kaizenOrange.opacity(0.08) }
        return isCompleted ? Color.kaizenTeal.opacity(0.15) : Color.white.opacity(0.06)
    }

    private var rowBorderColor: Color {
        if habit.isPaused { return Color.kaizenPurple.opacity(0.15) }
        if isSkippedToday { return Color.kaizenOrange.opacity(0.2) }
        return isCompleted ? Color.kaizenTeal.opacity(0.25) : Color.white.opacity(0.06)
    }
}

#Preview {
    let habit = Habit(name: "Early Start", emoji: "⏰", colorHex: "#00E5C8")
    return HabitRowView(habit: habit, date: Date(), onToggle: {})
        .background(Color.bgPrimary)
}
