//
//  MindsetView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct MindsetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [MindsetLog]

    @State private var energy: Double = 50
    @State private var focus: Double = 50
    @State private var mood: Double = 50
    @State private var selectedDay: Int = 3

    private var todayLog: MindsetLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return logs.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    private var last7Days: [MindsetLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
        return logs.filter {
            let d = calendar.startOfDay(for: $0.date)
            return d >= start && d <= today
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("This week")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                    Text("Mindset Tracker")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // Today's check-in sliders
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today's Check-in")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    MindsetSlider(label: "Energy", value: $energy, color: .kaizenOrange)
                    MindsetSlider(label: "Focus", value: $focus, color: .kaizenTeal)
                    MindsetSlider(label: "Mood", value: $mood, color: .kaizenPurple)

                    Button {
                        saveLog()
                    } label: {
                        Text(todayLog != nil ? "Update" : "Save")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.kaizenTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [.kaizenPurple.opacity(0.2), .kaizenTeal.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.kaizenPurple.opacity(0.25), lineWidth: 1)
                )

                // Day rings row
                if !last7Days.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(Array(last7Days.enumerated()), id: \.element.id) { index, log in
                            VStack(spacing: 4) {
                                DayScoreRingView(
                                    percent: log.overallScore,
                                    size: selectedDay == index ? 48 : 40,
                                    strokeWidth: selectedDay == index ? 6 : 5,
                                    color: selectedDay == index ? .kaizenTeal : .white.opacity(0.25)
                                )
                                Text(log.date.shortWeekday)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(selectedDay == index ? Color.kaizenTeal : Color.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture { selectedDay = index }
                        }
                    }
                }

                // Weekly Trends
                MindsetChartView(data: last7Days)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.bgPrimary)
        .onAppear { loadTodayValues() }
    }

    private func loadTodayValues() {
        if let log = todayLog {
            energy = Double(log.energy)
            focus = Double(log.focus)
            mood = Double(log.mood)
        }
    }

    private func saveLog() {
        if let existing = todayLog {
            existing.energy = Int(energy)
            existing.focus = Int(focus)
            existing.mood = Int(mood)
        } else {
            let log = MindsetLog(
                date: Date(),
                energy: Int(energy),
                focus: Int(focus),
                mood: Int(mood)
            )
            modelContext.insert(log)
        }
        try? modelContext.save()
    }
}

// MARK: - Mindset Slider

private struct MindsetSlider: View {
    let label: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * (value / 100), height: 8)
                        .shadow(color: color.opacity(0.6), radius: 8)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let pct = drag.location.x / geo.size.width
                            value = min(100, max(0, pct * 100))
                        }
                )
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    MindsetView()
        .modelContainer(for: [MindsetLog.self], inMemory: true)
}
