//
//  AddTaskView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .normal
    @State private var category: TaskCategory = .other
    @State private var taskDate: Date
    @FocusState private var titleFocused: Bool
    @FocusState private var notesFocused: Bool

    // MARK: - Init

    init(initialDate: Date = Date()) {
        _taskDate = State(initialValue: Calendar.current.startOfDay(for: initialDate))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        TextField("What needs to be done?", text: $title)
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.borderDefault, lineWidth: 1)
                            )
                            .focused($titleFocused)
                    }

                    // Notes field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        TextField("Add details, checklist, or any notes…", text: $notes, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .lineLimit(3...8)
                            .padding(16)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(notes.isEmpty ? Color.borderDefault : Color.kaizenTeal.opacity(0.4), lineWidth: 1)
                            )
                            .focused($notesFocused)
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 15))
                                .foregroundColor(Color.kaizenTeal)
                            Spacer()
                            DatePicker("", selection: $taskDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(Color.kaizenTeal)
                                .colorScheme(.dark)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.borderDefault, lineWidth: 1)
                        )
                    }

                    // Priority picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        HStack(spacing: 10) {
                            PriorityButton(label: "⚡ Top 3", isSelected: priority == .top3) {
                                priority = .top3
                            }
                            PriorityButton(label: "Normal", isSelected: priority == .normal) {
                                priority = .normal
                            }
                        }
                    }

                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(TaskCategory.allCases, id: \.self) { cat in
                                Button {
                                    category = cat
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(cat.emoji)
                                            .font(.system(size: 14))
                                        Text(cat.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(category == cat ? .white : Color.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(category == cat ? Color.kaizenTeal.opacity(0.2) : Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(category == cat ? Color.kaizenTeal : .clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    Spacer()

                    // Save button
                    Button {
                        saveTask()
                    } label: {
                        Text("Add Task")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(title.isEmpty ? Color.kaizenTeal.opacity(0.3) : Color.kaizenTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.textSecondary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        titleFocused = false
                        notesFocused = false
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.kaizenTeal)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func saveTask() {
        let task = DailyTask(title: title, notes: notes, date: taskDate, priority: priority, category: category)
        modelContext.insert(task)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Priority Button

private struct PriorityButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.kaizenTeal.opacity(0.2) : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.kaizenTeal : .clear, lineWidth: 1)
                )
        }
    }
}

#Preview {
    AddTaskView()
        .modelContainer(for: [DailyTask.self], inMemory: true)
}
