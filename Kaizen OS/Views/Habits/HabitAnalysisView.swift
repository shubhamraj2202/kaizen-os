//
//  HabitAnalysisView.swift
//  Kaizen OS
//

import SwiftUI

struct HabitAnalysisView: View {
    let habits: [Habit]

    private var sorted: [Habit] {
        habits.filter(\.isActive)
            .sorted { $0.completionRate30Days > $1.completionRate30Days }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ANALYSIS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.textTertiary)
                    .tracking(0.8)
                Spacer()
                Text("30 days")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.kaizenTeal)
            }

            if sorted.isEmpty {
                Text("Add habits to see analysis")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(sorted) { habit in
                        HabitBarRow(habit: habit)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.borderDefault, lineWidth: 1)
        )
    }
}

// MARK: - Single habit bar row

private struct HabitBarRow: View {
    let habit: Habit
    @State private var animatedRate: Double = 0

    private var barColor: Color {
        let r = habit.completionRate30Days
        if r >= 0.70 { return .kaizenTeal }
        if r >= 0.40 { return .kaizenOrange }
        return .kaizenCoral
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(habit.emoji)
                .font(.system(size: 17))
                .frame(width: 26)

            Text(habit.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(minWidth: 60, maxWidth: 100, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * animatedRate, height: 8)
                        .shadow(color: barColor.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 8)

            Text("\(Int(habit.completionRate30Days * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(barColor)
                .frame(width: 34, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                animatedRate = habit.completionRate30Days
            }
        }
    }
}
