//
//  TaskListView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

private enum CalendarMode: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyTask.sortOrder) private var allTasks: [DailyTask]
    @State private var showAddTask = false
    @State private var hapticTrigger = 0
    @State private var calendarMode: CalendarMode = .week
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var calendarAnchor = Calendar.current.startOfDay(for: Date())

    private let cal = Calendar.current
    private var todayStart: Date { cal.startOfDay(for: Date()) }

    // MARK: - Task Filters

    private var selectedStart: Date { selectedDate }
    private var selectedEnd: Date { cal.date(byAdding: .day, value: 1, to: selectedDate)! }

    private var selectedTasks: [DailyTask] {
        allTasks
            .filter { $0.date >= selectedStart && $0.date < selectedEnd }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var top3: [DailyTask] { selectedTasks.filter { $0.priority == .top3 } }
    private var otherTasks: [DailyTask] { selectedTasks.filter { $0.priority == .normal } }
    private var completedCount: Int { selectedTasks.filter(\.isCompleted).count }

    private var progressPct: Double {
        guard !selectedTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(selectedTasks.count)
    }

    private var datesWithTasks: Set<Date> {
        Set(allTasks.map { cal.startOfDay(for: $0.date) })
    }

    private var headerTitle: String {
        if cal.isDateInToday(selectedDate) { return "Today" }
        if cal.isDateInTomorrow(selectedDate) { return "Tomorrow" }
        if cal.isDateInYesterday(selectedDate) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
        return f.string(from: selectedDate)
    }

    // MARK: - Week Helpers

    private var mondayOfAnchor: Date {
        let weekday = cal.component(.weekday, from: calendarAnchor)
        let daysToMon = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysToMon, to: calendarAnchor)!
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: mondayOfAnchor) }
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }

    // MARK: - Month Helpers

    private var displayedMonthStart: Date {
        var comps = cal.dateComponents([.year, .month], from: calendarAnchor)
        comps.day = 1
        return cal.date(from: comps)!
    }

    private var leadingBlanks: Int {
        let weekday = cal.component(.weekday, from: displayedMonthStart)
        return (weekday + 5) % 7
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: displayedMonthStart)!.count
    }

    private func dateFor(day: Int) -> Date {
        cal.date(byAdding: .day, value: day - 1, to: displayedMonthStart)!
    }

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: calendarAnchor)
    }

    // MARK: - Year Helpers

    private var yearStart: Date {
        var comps = cal.dateComponents([.year], from: calendarAnchor)
        comps.month = 1; comps.day = 1
        return cal.date(from: comps)!
    }

    private var yearLabel: String {
        let f = DateFormatter(); f.dateFormat = "yyyy"
        return f.string(from: calendarAnchor)
    }

    // 7-row × N-col matrix of dates (nil = padding). Week starts Monday.
    private var yearColumns: [[Date?]] {
        // Day-of-week offset so column 0 = Monday
        let startWeekday = (cal.component(.weekday, from: yearStart) + 5) % 7 // Mon=0
        // Total day slots: 366 days max + leading padding
        let daysInYear = cal.range(of: .day, in: .year, for: yearStart)!.count
        let totalSlots = startWeekday + daysInYear
        let numCols = Int(ceil(Double(totalSlots) / 7.0))
        var cols: [[Date?]] = Array(repeating: Array(repeating: nil, count: 7), count: numCols)
        for slot in 0..<daysInYear {
            let idx = startWeekday + slot
            let col = idx / 7
            let row = idx % 7
            cols[col][row] = cal.date(byAdding: .day, value: slot, to: yearStart)
        }
        return cols
    }

    // Returns (column index, month abbreviation) for month labels
    private var yearMonthLabels: [(col: Int, label: String)] {
        let f = DateFormatter(); f.dateFormat = "MMM"
        var result: [(Int, String)] = []
        var current: Date? = nil
        let startWeekday = (cal.component(.weekday, from: yearStart) + 5) % 7
        let daysInYear = cal.range(of: .day, in: .year, for: yearStart)!.count
        for slot in 0..<daysInYear {
            let date = cal.date(byAdding: .day, value: slot, to: yearStart)!
            let month = cal.component(.month, from: date)
            if current == nil || cal.component(.month, from: current!) != month {
                current = date
                let col = (startWeekday + slot) / 7
                result.append((col, f.string(from: date)))
            }
        }
        return result
    }

    private func yearTaskCellColor(for date: Date) -> Color {
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        let dayTasks = allTasks.filter { $0.date >= dayStart && $0.date < dayEnd }
        guard !dayTasks.isEmpty else { return Color.white.opacity(0.04) }
        let done = dayTasks.filter(\.isCompleted).count
        if done == dayTasks.count { return Color.kaizenTeal }
        if done > 0 { return Color.kaizenTeal.opacity(0.45) }
        return Color.kaizenOrange.opacity(0.3)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {

                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Date().shortWeekday)
                                .font(.system(size: 13))
                                .foregroundColor(Color.textSecondary)
                            Text("Task List")
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        calendarModeToggle
                    }
                    .padding(.top, 8)

                    // Calendar
                    switch calendarMode {
                    case .week:  weekCalendarView
                    case .month: monthCalendarView
                    case .year:  yearCalendarView
                    }

                    // Selected date label
                    Text(headerTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Progress bar
                    if !selectedTasks.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(completedCount) of \(selectedTasks.count) done")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.textSecondary)
                                Spacer()
                                Text("\(Int(progressPct * 100))%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.kaizenTeal)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.08)).frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(LinearGradient(colors: [.kaizenTeal, .kaizenPurple], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * progressPct, height: 6)
                                        .shadow(color: .kaizenTeal.opacity(0.4), radius: 10)
                                        .animation(.easeInOut(duration: 0.3), value: progressPct)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.bottom, 4)
                    }

                    // Top 3
                    if !top3.isEmpty {
                        VStack(spacing: 0) {
                            Text("⚡ TOP 3 PRIORITIES")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.kaizenTeal)
                                .tracking(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                            ForEach(Array(top3.enumerated()), id: \.element.id) { index, task in
                                TaskRow(task: task, showDivider: index < top3.count - 1) {
                                    hapticTrigger += 1
                                    task.toggle()
                                    try? modelContext.save()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.kaizenTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.kaizenTeal.opacity(0.15), lineWidth: 1))
                    }

                    // Other tasks
                    if !otherTasks.isEmpty {
                        VStack(spacing: 8) {
                            Text("OTHER TASKS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.textTertiary)
                                .tracking(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ForEach(otherTasks) { task in
                                OtherTaskRow(task: task) {
                                    hapticTrigger += 1
                                    task.toggle()
                                    try? modelContext.save()
                                }
                            }
                        }
                    }

                    // Empty state
                    if selectedTasks.isEmpty {
                        VStack(spacing: 12) {
                            Text("📋").font(.system(size: 48))
                            Text("No tasks \(cal.isDateInToday(selectedDate) ? "today" : "on this day")")
                                .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                            Text("Tap + to add a task")
                                .font(.system(size: 14)).foregroundColor(Color.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .background(Color.bgPrimary)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: hapticTrigger)

            Button { showAddTask = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 56)
                    .background(Color.kaizenTeal)
                    .clipShape(Circle())
                    .shadow(color: .kaizenTeal.opacity(0.4), radius: 16)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView(initialDate: selectedDate)
        }
    }

    // MARK: - Calendar Mode Toggle

    private var calendarModeToggle: some View {
        HStack(spacing: 2) {
            ForEach(CalendarMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { calendarMode = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundColor(calendarMode == mode ? .black : Color.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(calendarMode == mode ? Color.kaizenTeal : .clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Week Calendar View

    private var weekCalendarView: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        calendarAnchor = cal.date(byAdding: .day, value: -7, to: calendarAnchor)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                Spacer()
                Text(weekRangeLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        calendarAnchor = cal.date(byAdding: .day, value: 7, to: calendarAnchor)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }

            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { day in
                    let dayStart = cal.startOfDay(for: day)
                    WeekDayCell(
                        date: day,
                        isSelected: dayStart == selectedDate,
                        isToday: cal.isDateInToday(day),
                        hasTask: datesWithTasks.contains(dayStart)
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedDate = dayStart
                            calendarAnchor = day
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
    }

    // MARK: - Month Calendar View

    private var monthCalendarView: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        calendarAnchor = cal.date(byAdding: .month, value: -1, to: calendarAnchor)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                Spacer()
                Text(monthLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        calendarAnchor = cal.date(byAdding: .month, value: 1, to: calendarAnchor)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(["M","T","W","T","F","S","S"][i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid — always fill complete rows to avoid last-row cell stretching
            let totalCells = leadingBlanks + daysInMonth
            let trailingBlanks = (7 - totalCells % 7) % 7
            let gridTotal = totalCells + trailingBlanks
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<gridTotal, id: \.self) { index in
                    if index < leadingBlanks || index >= totalCells {
                        Color.clear.frame(height: 36)
                    } else {
                        let day = index - leadingBlanks + 1
                        let date = dateFor(day: day)
                        let dayStart = cal.startOfDay(for: date)
                        MonthDayCell(
                            day: day,
                            isSelected: dayStart == selectedDate,
                            isToday: cal.isDateInToday(date),
                            hasTask: datesWithTasks.contains(dayStart)
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedDate = dayStart
                                calendarAnchor = date
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
    }

    // MARK: - Year Calendar View

    private var yearCalendarView: some View {
        VStack(spacing: 10) {
            // Year nav header
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        calendarAnchor = cal.date(byAdding: .year, value: -1, to: calendarAnchor)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                Spacer()
                Text(yearLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        calendarAnchor = cal.date(byAdding: .year, value: 1, to: calendarAnchor)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }

            // Contribution graph
            let cols = yearColumns
            let monthLabels = yearMonthLabels
            let cellSize: CGFloat = 11
            let cellSpacing: CGFloat = 3
            let rowLabels = ["M","","W","","F","","S"]

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // Month label row
                    HStack(alignment: .top, spacing: cellSpacing) {
                        // offset for row-label column
                        Text("").frame(width: 14)
                        ZStack(alignment: .topLeading) {
                            HStack(spacing: cellSpacing) {
                                ForEach(0..<cols.count, id: \.self) { _ in
                                    Color.clear.frame(width: cellSize)
                                }
                            }
                            ForEach(monthLabels, id: \.col) { item in
                                Text(item.label)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color.textTertiary)
                                    .offset(x: CGFloat(item.col) * (cellSize + cellSpacing))
                            }
                        }
                    }
                    .frame(height: 14)

                    // Grid rows
                    HStack(alignment: .top, spacing: cellSpacing) {
                        // Day-of-week labels (Mon, Wed, Fri, Sun)
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { row in
                                Text(rowLabels[row])
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(Color.textTertiary)
                                    .frame(width: 14, height: cellSize)
                            }
                        }

                        // Cell columns
                        HStack(alignment: .top, spacing: cellSpacing) {
                            ForEach(0..<cols.count, id: \.self) { col in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { row in
                                        if let date = cols[col][row] {
                                            let isFuture = date > todayStart
                                            let isSelected = cal.startOfDay(for: date) == selectedDate
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    selectedDate = cal.startOfDay(for: date)
                                                    calendarAnchor = date
                                                }
                                            } label: {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(isSelected ? Color.white : (isFuture ? Color.white.opacity(0.04) : yearTaskCellColor(for: date)))
                                                    .frame(width: cellSize, height: cellSize)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 2)
                                                            .stroke(cal.isDateInToday(date) ? Color.kaizenTeal : Color.clear, lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            Color.clear.frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Legend
            HStack(spacing: 12) {
                Spacer()
                HStack(spacing: 4) {
                    ForEach([Color.white.opacity(0.04), Color.kaizenOrange.opacity(0.3), Color.kaizenTeal.opacity(0.45), Color.kaizenTeal], id: \.self) { c in
                        RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 11, height: 11)
                    }
                    Text("Less → More done")
                        .font(.system(size: 10))
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderDefault, lineWidth: 1))
    }
}

// MARK: - Week Day Cell

private struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTask: Bool
    let action: () -> Void

    private var dayNum: String { "\(Calendar.current.component(.day, from: date))" }
    private var weekLetter: String {
        ["S","M","T","W","T","F","S"][Calendar.current.component(.weekday, from: date) - 1]
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(weekLetter)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .black : Color.textTertiary)
                Text(dayNum)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? .black : (isToday ? Color.kaizenTeal : .white))
                Circle()
                    .fill(hasTask ? (isSelected ? Color.black.opacity(0.4) : Color.kaizenTeal) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? Color.kaizenTeal : (isToday ? Color.kaizenTeal.opacity(0.1) : Color.white.opacity(0.04)))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday && !isSelected ? Color.kaizenTeal.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Month Day Cell

private struct MonthDayCell: View {
    let day: Int
    let isSelected: Bool
    let isToday: Bool
    let hasTask: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.system(size: 13, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .black : (isToday ? Color.kaizenTeal : .white))
                Circle()
                    .fill(hasTask ? (isSelected ? Color.black.opacity(0.4) : Color.kaizenTeal) : Color.clear)
                    .frame(width: 3, height: 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(isSelected ? Color.kaizenTeal : (isToday ? Color.kaizenTeal.opacity(0.1) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Row (Top 3)

private struct TaskRow: View {
    let task: DailyTask
    let showDivider: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(task.isCompleted ? Color.kaizenTeal : .clear)
                            .frame(width: 24, height: 24)
                        if !task.isCompleted {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                .frame(width: 24, height: 24)
                        }
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(.black)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(task.isCompleted ? .white.opacity(0.35) : .white)
                            .strikethrough(task.isCompleted)
                            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(.system(size: 12))
                                .foregroundColor(Color.textTertiary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if showDivider {
                Divider().background(Color.white.opacity(0.05))
            }
        }
    }
}

// MARK: - Other Task Row

private struct OtherTaskRow: View {
    let task: DailyTask
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(task.isCompleted ? Color.kaizenTeal : .clear)
                        .frame(width: 22, height: 22)
                    if !task.isCompleted {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white.opacity(0.15), lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.black)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 14))
                        .foregroundStyle(task.isCompleted ? .white.opacity(0.3) : .white)
                        .strikethrough(task.isCompleted)
                        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.system(size: 12))
                            .foregroundColor(Color.textTertiary)
                            .lineLimit(2)
                    }
                }
                Spacer()

                Text(task.category.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TaskListView()
        .modelContainer(for: [DailyTask.self], inMemory: true)
}
