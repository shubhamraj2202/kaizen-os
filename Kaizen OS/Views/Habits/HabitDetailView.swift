//
//  HabitDetailView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMonth: Date
    @State private var hapticTrigger = 0

    private let cal = Calendar.current
    private let monthFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f
    }()
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    init(habit: Habit) {
        self.habit = habit
        var comps = Calendar.current.dateComponents([.year, .month], from: Date())
        comps.day = 1
        _selectedMonth = State(initialValue: Calendar.current.date(from: comps) ?? Date())
    }

    // MARK: - Stats

    private var totalCompletions: Int {
        habit.entries.filter(\.isCompleted).count
    }

    private var scheduleLabel: String {
        guard !habit.scheduledWeekdays.isEmpty else { return "Every day" }
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sorted = habit.scheduledWeekdays.sorted()
        if sorted == [1, 2, 3, 4, 5] { return "Mon–Fri" }
        if sorted == [0, 6] { return "Weekends" }
        return sorted.map { names[$0] }.joined(separator: ", ")
    }

    // MARK: - Monthly Data

    private var last12Months: [Date] {
        var comps = cal.dateComponents([.year, .month], from: Date())
        comps.day = 1
        guard let thisMonth = cal.date(from: comps) else { return [] }
        return (0..<12).reversed().compactMap {
            cal.date(byAdding: .month, value: -$0, to: thisMonth)
        }
    }

    private func completionRate(for monthStart: Date) -> Double {
        guard let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { return 0 }
        let today = cal.startOfDay(for: Date())
        let skipped = Set(habit.entries.filter { $0.isSkipped }.map { cal.startOfDay(for: $0.date) })
        var scheduled = 0
        var d = monthStart
        while d < monthEnd && d <= today {
            if habit.isScheduled(on: d) && !skipped.contains(d) { scheduled += 1 }
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        guard scheduled > 0 else { return 0 }
        let done = habit.entries.filter {
            let day = cal.startOfDay(for: $0.date)
            return day >= monthStart && day < monthEnd && day <= today && $0.isCompleted
        }.count
        return Double(done) / Double(scheduled)
    }

    private var monthlyStats: [(month: Date, rate: Double)] {
        last12Months.map { ($0, completionRate(for: $0)) }
    }

    private var bestMonthRate: Double {
        monthlyStats.map(\.rate).max() ?? 0
    }

    // MARK: - Calendar Helpers

    private var leadingBlanks: Int {
        let weekday = cal.component(.weekday, from: selectedMonth)
        return (weekday + 5) % 7
    }

    private var daysInSelectedMonth: Int {
        cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
    }

    private func dateFor(day: Int) -> Date {
        cal.date(byAdding: .day, value: day - 1, to: selectedMonth) ?? selectedMonth
    }

    private func cellState(for date: Date) -> HDCellState {
        let day = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: Date())
        guard day <= today else { return .future }
        guard habit.isScheduled(on: date) else { return .unscheduled }
        if let entry = habit.entries.first(where: { cal.startOfDay(for: $0.date) == day }) {
            if entry.isCompleted { return .done }
            if entry.isSkipped  { return .skipped }
        }
        return .missed
    }

    // MARK: - Toggle

    private func toggleDay(_ date: Date) {
        hapticTrigger += 1
        let day = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: Date())
        guard day <= today, habit.isScheduled(on: date) else { return }
        if let existing = habit.entries.first(where: { cal.startOfDay(for: $0.date) == day }) {
            existing.isCompleted ? existing.uncomplete() : existing.complete()
        } else {
            let entry = HabitEntry(date: day, habit: habit)
            entry.complete()
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        statsGrid
                        calendarSection
                        monthlyBarsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.kaizenTeal)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 14) {
            Text(habit.emoji)
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(Color.kaizenTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.kaizenTeal.opacity(0.2), lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text(habit.name)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(scheduleLabel, systemImage: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                    if let badge = habit.durationBadge {
                        Text(badge)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(badge == "🎉 Done!" ? Color.kaizenOrange : Color.kaizenPurple)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.kaizenPurple.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let items: [(String, String, String, Color)] = [
            ("🔥", "Streak",  "\(habit.currentStreak)d",                    .kaizenOrange),
            ("🏆", "Best",    "\(habit.longestStreak)d",                    .kaizenTeal),
            ("✅", "Total",   "\(totalCompletions)",                         .kaizenPurple),
            ("📊", "30-day",  "\(Int(habit.completionRate30Days * 100))%",   .kaizenTeal),
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.1) { emoji, label, value, color in
                VStack(spacing: 6) {
                    Text(emoji).font(.system(size: 22))
                    Text(value)
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.textTertiary)
                        .tracking(0.3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.borderDefault, lineWidth: 1))
            }
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPLETION HISTORY")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.textTertiary)
                .tracking(0.8)

            // Month chip selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(last12Months, id: \.self) { month in
                        let isSelected = cal.isDate(month, equalTo: selectedMonth, toGranularity: .month)
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { selectedMonth = month }
                        } label: {
                            Text(monthFmt.string(from: month))
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .foregroundColor(isSelected ? .black : Color.textSecondary)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(isSelected ? Color.kaizenTeal : Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 1)
            }

            // Grid
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(weekdayLabels[i])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                let totalCells = leadingBlanks + daysInSelectedMonth
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                    ForEach(0..<totalCells, id: \.self) { idx in
                        if idx < leadingBlanks {
                            Color.clear.frame(height: 38)
                        } else {
                            let dayNum = idx - leadingBlanks + 1
                            let date = dateFor(day: dayNum)
                            HDDayCell(
                                day: dayNum,
                                state: cellState(for: date),
                                isToday: cal.isDateInToday(date)
                            ) { toggleDay(date) }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))

            // Legend
            HStack(spacing: 14) {
                Spacer()
                legendDot(bg: Color.kaizenTeal.opacity(0.2),   stroke: Color.kaizenTeal.opacity(0.4),   label: "Done")
                legendDot(bg: Color.kaizenCoral.opacity(0.12), stroke: Color.kaizenCoral.opacity(0.3),  label: "Missed")
                legendDot(bg: Color.kaizenOrange.opacity(0.1), stroke: Color.kaizenOrange.opacity(0.25),label: "Skipped")
            }
        }
    }

    private func legendDot(bg: Color, stroke: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4)
                .fill(bg)
                .frame(width: 13, height: 13)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(stroke, lineWidth: 1))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.textTertiary)
        }
    }

    // MARK: - Monthly Bars Section

    private var monthlyBarsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MONTH BY MONTH")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.textTertiary)
                    .tracking(0.8)
                Spacer()
                if bestMonthRate > 0,
                   let best = monthlyStats.last(where: { $0.rate == bestMonthRate }) {
                    HStack(spacing: 3) {
                        Text("🏆")
                            .font(.system(size: 11))
                        Text("\(monthFmt.string(from: best.month)) · \(Int(bestMonthRate * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.kaizenTeal)
                    }
                }
            }

            VStack(spacing: 8) {
                ForEach(monthlyStats, id: \.month) { stat in
                    let isBest = stat.rate == bestMonthRate && stat.rate > 0
                    HStack(spacing: 10) {
                        Text(monthFmt.string(from: stat.month))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                            .frame(width: 32, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 22)
                                if stat.rate > 0 {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(isBest
                                              ? LinearGradient(colors: [.kaizenTeal, .kaizenPurple], startPoint: .leading, endPoint: .trailing)
                                              : LinearGradient(colors: [Color.kaizenPurple.opacity(0.65), Color.kaizenPurple.opacity(0.45)], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: max(geo.size.width * stat.rate, 6), height: 22)
                                        .shadow(color: isBest ? .kaizenTeal.opacity(0.3) : .clear, radius: 8)
                                }
                            }
                        }
                        .frame(height: 22)

                        Text(stat.rate > 0 ? "\(Int(stat.rate * 100))%" : "—")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isBest ? Color.kaizenTeal : Color.textTertiary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
        }
    }
}

// MARK: - Cell State

private enum HDCellState {
    case done, missed, skipped, future, unscheduled
}

// MARK: - Day Cell

private struct HDDayCell: View {
    let day: Int
    let state: HDCellState
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(day)")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundStyle(fgColor)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isToday ? Color.kaizenTeal : strokeColor, lineWidth: isToday ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(state == .future || state == .unscheduled)
    }

    private var bgColor: Color {
        switch state {
        case .done:                  return Color.kaizenTeal.opacity(0.2)
        case .missed:                return Color.kaizenCoral.opacity(0.12)
        case .skipped:               return Color.kaizenOrange.opacity(0.1)
        case .future, .unscheduled:  return Color.white.opacity(0.03)
        }
    }

    private var strokeColor: Color {
        switch state {
        case .done:    return Color.kaizenTeal.opacity(0.4)
        case .missed:  return Color.kaizenCoral.opacity(0.3)
        case .skipped: return Color.kaizenOrange.opacity(0.25)
        default:       return Color.clear
        }
    }

    private var fgColor: Color {
        switch state {
        case .done:    return Color.kaizenTeal
        case .missed:  return Color.kaizenCoral
        case .skipped: return Color.kaizenOrange
        default:       return Color.white.opacity(0.2)
        }
    }
}

#Preview {
    let habit = Habit(name: "Morning Run", emoji: "🏃", colorHex: "#00E5C8")
    return HabitDetailView(habit: habit)
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
