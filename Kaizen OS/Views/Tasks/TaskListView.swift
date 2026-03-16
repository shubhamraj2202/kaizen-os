//
//  TaskListView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyTask.sortOrder) private var allTasks: [DailyTask]
    @State private var showAddTask = false
    @State private var hapticTrigger = 0
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    private var todayStart: Date { Calendar.current.startOfDay(for: Date()) }

    // Date range displayed in the strip: 7 days back → 7 days forward
    private var dateRange: [Date] {
        (-7...7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: todayStart)
        }
    }

    private var selectedStart: Date { selectedDate }
    private var selectedEnd: Date { Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)! }

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

    private var headerTitle: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Today" }
        if Calendar.current.isDateInTomorrow(selectedDate) { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Date().shortWeekday)
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary)
                        Text("Task List")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    // Date strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(dateRange, id: \.self) { date in
                                DatePill(date: date, isSelected: date == selectedDate, isToday: date == todayStart) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedDate = date
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, -20)

                    // Selected date label
                    Text(headerTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Progress bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(completedCount) of \(selectedTasks.count) completed")
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
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [.kaizenTeal, .kaizenPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progressPct, height: 6)
                                    .shadow(color: .kaizenTeal.opacity(0.4), radius: 10)
                                    .animation(.easeInOut(duration: 0.3), value: progressPct)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.bottom, 4)

                    // Top 3 section
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.kaizenTeal.opacity(0.15), lineWidth: 1)
                        )
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
                            Text("📋")
                                .font(.system(size: 48))
                            Text("No tasks \(Calendar.current.isDateInToday(selectedDate) ? "today" : "on this day")")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Tap + to add a task")
                                .font(.system(size: 14))
                                .foregroundColor(Color.textTertiary)
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

            // FAB
            Button {
                showAddTask = true
            } label: {
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
}

// MARK: - Date Pill

private struct DatePill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private var dayNum: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var weekLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(weekLetter)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .black : Color.textTertiary)
                Text(dayNum)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? .black : .white)

                Circle()
                    .fill(isToday && !isSelected ? Color.kaizenTeal : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 44, height: 58)
            .background(isSelected ? Color.kaizenTeal : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isToday && !isSelected ? Color.kaizenTeal.opacity(0.4) : .clear, lineWidth: 1.5)
            )
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

                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(task.isCompleted ? .white.opacity(0.35) : .white)
                        .strikethrough(task.isCompleted)
                        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
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

                Text(task.title)
                    .font(.system(size: 14))
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.3) : .white)
                    .strikethrough(task.isCompleted)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
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
