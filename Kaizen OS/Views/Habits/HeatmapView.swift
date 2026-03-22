//
//  HeatmapView.swift
//  Kaizen OS
//

import SwiftUI

// MARK: - Heatmap Mode

private enum HeatmapMode: String, CaseIterable {
    case week  = "Week"
    case month = "Month"
    case year  = "Year"
}

// MARK: - HeatmapView

struct HeatmapView: View {
    let habits: [Habit]

    @State private var mode: HeatmapMode = .month
    @State private var anchor: Date = Date()

    private let cal = Calendar.current
    private let monFirstLetters = ["M","T","W","T","F","S","S"]

    // MARK: - Shared helpers

    private func completion(for date: Date) -> Double {
        let active = habits.filter(\.isActive)
        guard !active.isEmpty else { return 0 }
        let done = active.filter { $0.isCompleted(on: date) }.count
        return Double(done) / Double(active.count)
    }

    private func cellColor(_ c: Double, isFuture: Bool) -> Color {
        if isFuture { return Color.white.opacity(0.03) }
        if c >= 1.0  { return Color.kaizenTeal }
        if c  > 0    { return Color.kaizenTeal.opacity(0.55) }
        return Color.white.opacity(0.07)
    }

    private func isFutureDate(_ date: Date) -> Bool {
        cal.startOfDay(for: date) > cal.startOfDay(for: Date())
    }

    // MARK: - Week helpers

    private var weekStart: Date {
        let weekday = cal.component(.weekday, from: anchor)
        let daysToMon = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysToMon, to: cal.startOfDay(for: anchor))!
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }

    private var weekCompletionPct: Int {
        let pastDays = weekDays.filter { !isFutureDate($0) }
        guard !pastDays.isEmpty else { return 0 }
        let sum = pastDays.reduce(0.0) { $0 + completion(for: $1) }
        return Int(sum / Double(pastDays.count) * 100)
    }

    // MARK: - Month helpers

    private var monthStart: Date {
        var comps = cal.dateComponents([.year, .month], from: anchor)
        comps.day = 1
        return cal.date(from: comps)!
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    private var leadingBlanks: Int {
        let weekday = cal.component(.weekday, from: monthStart)
        return (weekday + 5) % 7
    }

    private func isFutureMonthDay(_ dayNum: Int) -> Bool {
        let today = Date()
        if cal.isDate(today, equalTo: anchor, toGranularity: .month) {
            return dayNum > cal.component(.day, from: today)
        }
        return monthStart > cal.startOfDay(for: today)
    }

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: anchor)
    }

    private var monthCompletionPct: Int {
        let active = habits.filter(\.isActive)
        guard !active.isEmpty else { return 0 }
        var total = 0; var completed = 0
        for day in 1...daysInMonth {
            guard !isFutureMonthDay(day),
                  let date = cal.date(byAdding: .day, value: day - 1, to: monthStart)
            else { continue }
            for habit in active {
                total += 1
                if habit.isCompleted(on: date) { completed += 1 }
            }
        }
        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    // MARK: - Year helpers

    private var yearStart: Date {
        var comps = cal.dateComponents([.year], from: anchor)
        comps.month = 1; comps.day = 1
        return cal.date(from: comps)!
    }

    private var yearLabel: String { "\(cal.component(.year, from: anchor))" }

    // Returns week-columns: each column is [Date?] × 7 (Mon=0 … Sun=6)
    // nil = day outside the anchor year
    private var yearColumns: [[Date?]] {
        let jan1 = yearStart
        let jan1wd = cal.component(.weekday, from: jan1)
        let gridStart = cal.date(byAdding: .day, value: -((jan1wd + 5) % 7), to: jan1)!

        var yearEndComps = cal.dateComponents([.year], from: anchor)
        yearEndComps.month = 12; yearEndComps.day = 31
        let dec31 = cal.date(from: yearEndComps)!
        let dec31wd = cal.component(.weekday, from: dec31)
        let gridEnd = cal.date(byAdding: .day, value: (dec31wd == 1 ? 0 : 8 - dec31wd), to: dec31)!

        let anchorYear = cal.component(.year, from: anchor)
        var columns: [[Date?]] = []
        var weekBegin = gridStart

        while weekBegin <= gridEnd {
            let week: [Date?] = (0..<7).map { d -> Date? in
                let date = cal.date(byAdding: .day, value: d, to: weekBegin)!
                return cal.component(.year, from: date) == anchorYear ? date : nil
            }
            columns.append(week)
            weekBegin = cal.date(byAdding: .day, value: 7, to: weekBegin)!
        }
        return columns
    }

    // Column index where each month name should appear
    private var monthLabelPositions: [(label: String, col: Int)] {
        let f = DateFormatter(); f.dateFormat = "MMM"
        var result: [(String, Int)] = []
        let cols = yearColumns
        for (idx, week) in cols.enumerated() {
            for dayOpt in week {
                guard let date = dayOpt, cal.component(.day, from: date) == 1 else { continue }
                result.append((f.string(from: date), idx))
                break
            }
        }
        return result
    }

    private var yearCompletionPct: Int {
        let active = habits.filter(\.isActive)
        guard !active.isEmpty else { return 0 }
        var total = 0; var completed = 0
        let today = cal.startOfDay(for: Date())
        for week in yearColumns {
            for dayOpt in week {
                guard let date = dayOpt else { continue }
                if cal.startOfDay(for: date) > today { continue }
                for habit in active {
                    total += 1
                    if habit.isCompleted(on: date) { completed += 1 }
                }
            }
        }
        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    // MARK: - Navigation

    private var isAtPresent: Bool {
        switch mode {
        case .week:
            return weekDays.contains { cal.isDateInToday($0) }
                || (weekDays.first ?? anchor) > Date()
        case .month:
            return cal.isDate(anchor, equalTo: Date(), toGranularity: .month)
        case .year:
            return cal.component(.year, from: anchor) >= cal.component(.year, from: Date())
        }
    }

    private func navigate(by delta: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch mode {
            case .week:
                anchor = cal.date(byAdding: .day, value: delta * 7, to: anchor) ?? anchor
            case .month:
                anchor = cal.date(byAdding: .month, value: delta, to: anchor) ?? anchor
            case .year:
                anchor = cal.date(byAdding: .year, value: delta, to: anchor) ?? anchor
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Title + mode toggle
            HStack {
                Text("\(mode.rawValue) Heatmap")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(HeatmapMode.allCases, id: \.self) { m in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                        } label: {
                            Text(m.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(mode == m ? .black : Color.textSecondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(mode == m ? Color.kaizenTeal : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(2)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }

            // Navigation row
            HStack {
                Button { navigate(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                Spacer()
                Text(navigationLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textSecondary)
                Spacer()
                Button { navigate(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isAtPresent ? Color.textTertiary : Color.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(isAtPresent ? 0.02 : 0.06))
                        .clipShape(Circle())
                }
                .disabled(isAtPresent)
            }

            // Calendar content
            Group {
                switch mode {
                case .week:  weekView
                case .month: monthView
                case .year:  yearView
                }
            }

            // Completion stat
            HStack {
                Spacer()
                Text("\(completionPct)% \(statLabel)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.kaizenTeal)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.borderDefault, lineWidth: 1))
    }

    private var navigationLabel: String {
        switch mode {
        case .week:  return weekRangeLabel
        case .month: return monthLabel
        case .year:  return yearLabel
        }
    }

    private var completionPct: Int {
        switch mode {
        case .week:  return weekCompletionPct
        case .month: return monthCompletionPct
        case .year:  return yearCompletionPct
        }
    }

    private var statLabel: String {
        switch mode {
        case .week:  return "this week"
        case .month: return "this month"
        case .year:  return "this year"
        }
    }

    // MARK: - Week View

    private var weekView: some View {
        HStack(spacing: 6) {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { idx, day in
                let future = isFutureDate(day)
                let c = future ? 0.0 : completion(for: day)
                let isToday = cal.isDateInToday(day)
                Button { } label: {
                    VStack(spacing: 5) {
                        Text(monFirstLetters[idx])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Text("\(cal.component(.day, from: day))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(future ? .white.opacity(0.2) : .white)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(cellColor(c, isFuture: future))
                            .frame(height: 36)
                            .shadow(color: (!future && c > 0) ? Color.kaizenTeal.opacity(0.3) : .clear, radius: 4)
                        Text(future ? "" : "\(Int(c * 100))%")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isToday ? Color.kaizenTeal.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday ? Color.kaizenTeal.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 4) {
            // Weekday header row
            HStack(spacing: 0) {
                ForEach(monFirstLetters.indices, id: \.self) { i in
                    Text(monFirstLetters[i])
                        .font(.system(size: 10))
                        .foregroundColor(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
                ForEach(1...max(1, daysInMonth), id: \.self) { day in
                    let future = isFutureMonthDay(day)
                    let c = future ? 0.0 : completion(
                        for: cal.date(byAdding: .day, value: day - 1, to: monthStart) ?? Date()
                    )
                    let isToday: Bool = {
                        guard let date = cal.date(byAdding: .day, value: day - 1, to: monthStart)
                        else { return false }
                        return cal.isDateInToday(date)
                    }()

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(future ? Color.white.opacity(0.03) : cellColor(c, isFuture: false))
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: (!future && c > 0) ? Color.kaizenTeal.opacity(0.25) : .clear, radius: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isToday ? Color.kaizenTeal.opacity(0.8) : Color.clear, lineWidth: 1.5)
                            )
                        Text("\(day)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(future ? 0.15 : 0.5))
                            .padding(3)
                    }
                }
            }
        }
    }

    // MARK: - Year View

    private var yearView: some View {
        let cellSize: CGFloat  = 10
        let gap: CGFloat       = 3
        let cols               = yearColumns
        let labelPositions     = monthLabelPositions

        return HStack(alignment: .top, spacing: 4) {
            // Day-of-week labels (left side)
            VStack(spacing: gap) {
                Text("").frame(height: 12)   // spacer matching month label row
                ForEach(monFirstLetters.indices, id: \.self) { i in
                    Text(monFirstLetters[i])
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(Color.textTertiary)
                        .frame(width: 8, height: cellSize)
                }
            }

            // Scrollable grid
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: gap) {
                    // Month labels row
                    HStack(alignment: .top, spacing: gap) {
                        ForEach(cols.indices, id: \.self) { colIdx in
                            let label = labelPositions.first { $0.col == colIdx }?.label
                            Text(label ?? "")
                                .font(.system(size: 7, weight: .medium))
                                .foregroundColor(label != nil ? Color.textTertiary : Color.clear)
                                .frame(width: cellSize, height: 12, alignment: .leading)
                        }
                    }

                    // 7 day rows
                    ForEach(0..<7, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(cols.indices, id: \.self) { colIdx in
                                if let date = cols[colIdx][row] {
                                    let future = isFutureDate(date)
                                    let c = future ? 0.0 : completion(for: date)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(cellColor(c, isFuture: future))
                                        .frame(width: cellSize, height: cellSize)
                                } else {
                                    Color.clear.frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HeatmapView(habits: [])
        .padding(20)
        .background(Color.bgPrimary)
}
