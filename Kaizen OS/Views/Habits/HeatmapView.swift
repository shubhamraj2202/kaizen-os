//
//  HeatmapView.swift
//  Kaizen OS
//

import SwiftUI

struct HeatmapView: View {
    let habits: [Habit]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekDayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private var calendar: Calendar { Calendar.current }

    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps) ?? Date()
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    /// Offset so day 1 falls on the correct weekday column (Mon = 0)
    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday + 5) % 7
    }

    private var todayDay: Int {
        calendar.component(.day, from: Date())
    }

    private var monthCompletion: Int {
        let active = habits.filter(\.isActive)
        guard !active.isEmpty, todayDay > 0 else { return 0 }
        var total = 0
        var completed = 0
        for day in 1...todayDay {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            for habit in active {
                total += 1
                if habit.isCompleted(on: date) { completed += 1 }
            }
        }
        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    private func completion(day: Int) -> Double {
        guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { return 0 }
        let active = habits.filter(\.isActive)
        guard !active.isEmpty else { return 0 }
        let done = active.filter { $0.isCompleted(on: date) }.count
        return Double(done) / Double(active.count)
    }

    private func cellColor(_ c: Double) -> Color {
        if c >= 1.0 { return .kaizenTeal }
        if c > 0 { return .kaizenTeal.opacity(0.55) }
        return .white.opacity(0.07)
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

            // Weekday header row (indexed to avoid duplicate-key issues with T/S)
            HStack(spacing: 0) {
                ForEach(weekDayLabels.indices, id: \.self) { i in
                    Text(weekDayLabels[i])
                        .font(.system(size: 10))
                        .foregroundColor(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                // Leading blank cells so day 1 aligns to the right weekday
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }

                // Day cells
                ForEach(1...max(1, daysInMonth), id: \.self) { day in
                    let isFuture = day > todayDay
                    let c = isFuture ? 0.0 : completion(day: day)
                    let isToday = day == todayDay

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isFuture ? Color.white.opacity(0.03) : cellColor(c))
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: (!isFuture && c > 0) ? .kaizenTeal.opacity(0.25) : .clear, radius: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isToday ? Color.kaizenTeal.opacity(0.7) : .clear, lineWidth: 1.5)
                            )

                        Text("\(day)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(isFuture ? 0.15 : 0.5))
                            .padding(3)
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

#Preview {
    HeatmapView(habits: [])
        .padding(20)
        .background(Color.bgPrimary)
}
