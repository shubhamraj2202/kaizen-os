//
//  KaizenWidget.swift
//  Kaizen OS
//
//  ─── SETUP REQUIRED ───────────────────────────────────────────────────────────
//  This file belongs in a WidgetKit Extension target, not the main app target.
//  Until the widget target is created, it sits in the project unassigned.
//
//  Steps to wire up:
//  1. In Xcode: File → New Target → Widget Extension
//     - Product Name: "KaizenWidget"
//     - Uncheck "Include Live Activity" and "Include Configuration App Intent"
//     - Click Finish, then Activate the scheme
//  2. Select this file (KaizenWidget.swift) → File Inspector → Target Membership
//     → UNCHECK "Kaizen OS" (main app), CHECK "KaizenWidget" (widget extension)
//  3. Do the same for: Habit.swift, HabitEntry.swift, Color+Theme.swift
//     (widget extension needs these — they must be members of BOTH targets)
//  4. Add @main back to KaizenWidgetBundle (see comment below — removed here to
//     avoid conflict with Kaizen_OSApp's @main while this file is unassigned)
//  5. Enable App Groups on BOTH targets (main app + widget):
//     Signing & Capabilities → + Capability → App Groups → group.com.shubh.kaizenos
//  ──────────────────────────────────────────────────────────────────────────────
//
//  KaizenOSApp.swift update needed — replace the ModelContainer init with:
//
//    let groupURL = FileManager.default
//        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.shubh.kaizenos")!
//        .appendingPathComponent("kaizen.store")
//    let config = ModelConfiguration(url: groupURL)
//    container = try ModelContainer(
//        for: Habit.self, HabitEntry.self, DailyTask.self, MindsetLog.self, UserProfile.self,
//        configurations: config
//    )
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct KaizenEntry: TimelineEntry {
    let date: Date
    let bestStreak: Int
    let todayScore: Int     // 0–100
    let completedCount: Int
    let totalCount: Int
}

// MARK: - Timeline Provider

struct KaizenProvider: TimelineProvider {
    func placeholder(in context: Context) -> KaizenEntry {
        KaizenEntry(date: Date(), bestStreak: 12, todayScore: 67, completedCount: 4, totalCount: 6)
    }

    func getSnapshot(in context: Context, completion: @escaping (KaizenEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KaizenEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh at the start of the next calendar day
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    // MARK: - Data Fetch via shared SwiftData store

    private func loadEntry() -> KaizenEntry {
        let appGroupID = "group.com.shubh.kaizenos"
        guard
            let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupID
            )
        else {
            return KaizenEntry(date: Date(), bestStreak: 0, todayScore: 0, completedCount: 0, totalCount: 0)
        }

        let storeURL = groupURL.appendingPathComponent("kaizen.store")
        let config = ModelConfiguration(url: storeURL)

        guard let container = try? ModelContainer(for: Habit.self, HabitEntry.self, configurations: config) else {
            return KaizenEntry(date: Date(), bestStreak: 0, todayScore: 0, completedCount: 0, totalCount: 0)
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
        let habits = (try? context.fetch(descriptor)) ?? []

        let today = Calendar.current.startOfDay(for: Date())
        let completed = habits.filter { $0.isCompleted(on: today) }.count
        let total = habits.count
        let score = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
        let bestStreak = habits.map(\.longestStreak).max() ?? 0

        return KaizenEntry(
            date: Date(),
            bestStreak: bestStreak,
            todayScore: score,
            completedCount: completed,
            totalCount: total
        )
    }
}

// MARK: - Small Widget View

struct KaizenWidgetSmallView: View {
    let entry: KaizenEntry

    var body: some View {
        ZStack {
            Color(hex: "#090E1A")

            VStack(spacing: 8) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: Double(entry.todayScore) / 100.0)
                        .stroke(
                            Color(hex: "#00E5C8"),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.todayScore)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 60, height: 60)

                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#00E5C8"))

                Text("habits done")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 11))
                    Text("\(entry.bestStreak)d")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#FF8C42"))
                }
            }
            .padding(12)
        }
        .containerBackground(Color(hex: "#090E1A"), for: .widget)
    }
}

// MARK: - Medium Widget View

struct KaizenWidgetMediumView: View {
    let entry: KaizenEntry

    var body: some View {
        ZStack {
            Color(hex: "#090E1A")

            HStack(spacing: 20) {
                // Ring + score
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: Double(entry.todayScore) / 100.0)
                            .stroke(
                                Color(hex: "#00E5C8"),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(entry.todayScore)%")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 72, height: 72)

                    Text("Today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // Stats
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HABITS DONE")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(0.6)
                        Text("\(entry.completedCount) / \(entry.totalCount)")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(Color(hex: "#00E5C8"))
                    }

                    Divider()
                        .background(Color.white.opacity(0.07))

                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(entry.bestStreak) day streak")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#FF8C42"))
                            Text("personal best")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .containerBackground(Color(hex: "#090E1A"), for: .widget)
    }
}

// MARK: - Widget Configuration

struct KaizenWidget: Widget {
    let kind: String = "KaizenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KaizenProvider()) { entry in
            KaizenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Kaizen OS")
        .description("Your daily habit score and best streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct KaizenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KaizenEntry

    var body: some View {
        switch family {
        case .systemSmall:
            KaizenWidgetSmallView(entry: entry)
        case .systemMedium:
            KaizenWidgetMediumView(entry: entry)
        default:
            KaizenWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle (entry point for the extension target)

@main
struct KaizenWidgetBundle: WidgetBundle {
    var body: some Widget {
        KaizenWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    KaizenWidget()
} timeline: {
    KaizenEntry(date: Date(), bestStreak: 12, todayScore: 67, completedCount: 4, totalCount: 6)
    KaizenEntry(date: Date(), bestStreak: 15, todayScore: 100, completedCount: 6, totalCount: 6)
}

#Preview(as: .systemMedium) {
    KaizenWidget()
} timeline: {
    KaizenEntry(date: Date(), bestStreak: 12, todayScore: 67, completedCount: 4, totalCount: 6)
}
