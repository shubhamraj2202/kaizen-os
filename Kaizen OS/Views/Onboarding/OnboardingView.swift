//
//  OnboardingView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var currentPage = 0
    @State private var userName = ""

    private var profile: UserProfile? { profiles.first }

    private let pages: [(emoji: String, title: String, subtitle: String)] = [
        ("改善", "Welcome to Kaizen OS", "Your personal life operating system.\nSmall daily improvements, big results."),
        ("✅", "Track Habits", "Build streaks, see your progress on a heatmap,\nand never miss a day."),
        ("📋", "Manage Tasks", "Set your Top 3 priorities each day.\nStay focused on what matters."),
        ("🧠", "Mindset Check-in", "Track energy, focus, and mood daily.\nSpot patterns and optimize your life."),
    ]

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if currentPage < pages.count {
                    // Onboarding pages
                    VStack(spacing: 20) {
                        Text(pages[currentPage].emoji)
                            .font(.system(size: 64))

                        Text(pages[currentPage].title)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(pages[currentPage].subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)
                } else {
                    // Name entry
                    VStack(spacing: 20) {
                        Text("👋")
                            .font(.system(size: 64))

                        Text("What's your name?")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white)

                        TextField("Enter your name", text: $userName)
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.borderDefault, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0...pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.kaizenTeal : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)

                // Continue / Get Started button
                Button {
                    if currentPage < pages.count {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage == pages.count ? "Get Started" : "Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.kaizenTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .kaizenTeal.opacity(0.4), radius: 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                if currentPage < pages.count {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage = pages.count
                        }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textTertiary)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func completeOnboarding() {
        if let existing = profile {
            existing.name = userName
            existing.onboardingCompleted = true
        } else {
            let newProfile = UserProfile(name: userName)
            newProfile.onboardingCompleted = true
            modelContext.insert(newProfile)
        }
        try? modelContext.save()
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
