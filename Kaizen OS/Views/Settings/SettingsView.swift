//
//  SettingsView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showPaywall = false
    @State private var showNotificationSettings = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("Preferences")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                    Text("Settings")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // Premium status
                Button {
                    if profile?.isPremium != true {
                        showPaywall = true
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile?.isPremium == true ? "Premium Active" : "Free Plan")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Text(profile?.isPremium == true ? "Unlimited habits unlocked" : "5 habits max")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textSecondary)
                        }
                        Spacer()
                        if profile?.isPremium != true {
                            Text("Upgrade")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.kaizenTeal)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.kaizenTeal)
                        }
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [.kaizenTeal.opacity(0.15), .kaizenPurple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.kaizenTeal.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Notifications section
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        detail: (profile?.dailyReminderEnabled == true) ? "On" : "Off"
                    ) {
                        showNotificationSettings = true
                    }
                }
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderDefault, lineWidth: 1)
                )

                // App info
                VStack(spacing: 0) {
                    SettingsInfoRow(icon: "info.circle", title: "Version", detail: "1.0.0")
                    SettingsInfoRow(icon: "heart.fill", title: "Made in", detail: "Tokyo 🇯🇵")
                }
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderDefault, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.bgPrimary)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showNotificationSettings) {
            if let profile {
                NotificationSettingsView(profile: profile)
            }
        }
    }
}

// MARK: - Notification Settings Sheet

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let profile: UserProfile

    @State private var dailyEnabled: Bool
    @State private var dailyTime: Date

    init(profile: UserProfile) {
        self.profile = profile
        _dailyEnabled = State(initialValue: profile.dailyReminderEnabled)
        _dailyTime = State(initialValue: profile.dailyReminderTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Daily reminder card
                    VStack(spacing: 0) {
                        // Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Daily Check-in Reminder")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Get a nudge to log your progress")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $dailyEnabled)
                                .tint(Color.kaizenTeal)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        if dailyEnabled {
                            Divider()
                                .background(Color.borderDefault)
                                .padding(.horizontal, 16)

                            HStack {
                                Text("Time")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                Spacer()
                                DatePicker("", selection: $dailyTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .tint(Color.kaizenTeal)
                                    .colorScheme(.dark)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.borderDefault, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.2), value: dailyEnabled)

                    Text("Per-habit reminders can be set when adding a habit.")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                    Spacer()

                    // Save button
                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.kaizenTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.textSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func save() {
        profile.dailyReminderEnabled = dailyEnabled
        profile.dailyReminderTime = dailyEnabled ? dailyTime : nil
        try? modelContext.save()

        Task {
            await NotificationManager.shared.requestAuthorization()
            if dailyEnabled {
                NotificationManager.shared.scheduleDailyReminder(time: dailyTime)
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
            }
        }

        dismiss()
    }
}

// MARK: - Settings Row (tappable)

private struct SettingsRow: View {
    let icon: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.kaizenTeal)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Info Row (non-tappable)

private struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.kaizenTeal)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
