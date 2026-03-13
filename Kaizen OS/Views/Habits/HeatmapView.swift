//
//  HeatmapView.swift
//  Kaizen OS
//

import SwiftUI

struct HeatmapView: View {
    let habits: [Habit]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"]

    private var monthCompletion: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -27, to: today) else { return 0 }
        let active = habits.filter(\.isActive)
        guard !active.isEmpty else { return 0 }

        var total = 0
        var completed = 0
        for dayOffset in 0...27 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            for habit in active {
                total += 1
                if habit.isCompleted(on: date) { completed += 1 }
            }
        }
        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    private func dayCompletion(daysAgo: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return 0 }
        let active = habits.filter(\.isActive)
        guard !active.isEmpty else { return 0 }
        let done = active.filter { $0.isCompleted(on: date) }.count
        return Double(done) / Double(active.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Monthly Heatmap")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(monthCompletion)% this month")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.kaizenTeal)
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10))
                        .foregroundColor(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Heatmap grid (4 weeks = 28 days)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<28, id: \.self) { index in
                    let daysAgo = 27 - index
                    let completion = dayCompletion(daysAgo: daysAgo)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(cellColor(completion: completion))
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(
                            color: completion > 0 ? .kaizenTeal.opacity(0.3) : .clear,
                            radius: 3
                        )
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

    private func cellColor(completion: Double) -> Color {
        if completion >= 1.0 {
            return .kaizenTeal
        } else if completion > 0 {
            return .kaizenTeal.opacity(0.65)
        } else {
            return .white.opacity(0.06)
        }
    }
}

#Preview {
    HeatmapView(habits: [])
        .padding(20)
        .background(Color.bgPrimary)
}
