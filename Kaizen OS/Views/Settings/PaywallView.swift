//
//  PaywallView.swift
//  Kaizen OS
//

import SwiftUI
import SwiftData
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private let store = StoreKitManager.shared

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.kaizenTeal, .kaizenPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Text("K")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundStyle(.black)
                    }

                    Text("Unlock Kaizen OS")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("One-time purchase. No subscriptions.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)

                    // Features
                    VStack(spacing: 12) {
                        FeatureRow(icon: "infinity", title: "Unlimited Habits", subtitle: "No more 5-habit cap")
                        FeatureRow(icon: "square.grid.2x2.fill", title: "Rich Widgets", subtitle: "Beautiful home screen widgets")
                        FeatureRow(icon: "heart.fill", title: "HealthKit Sync", subtitle: "Connect your health data")
                        FeatureRow(icon: "arrow.down.doc.fill", title: "CSV Export", subtitle: "Export all your data")
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.borderDefault, lineWidth: 1)
                    )

                    // Price button
                    Button {
                        Task {
                            try? await store.purchase()
                            if store.isPurchased {
                                profile?.isPremium = true
                                profile?.premiumPurchaseDate = Date()
                                try? modelContext.save()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if store.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Unlock for \(store.product?.displayPrice ?? "$4.99")")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.kaizenTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .kaizenTeal.opacity(0.4), radius: 16)
                    }
                    .disabled(store.isLoading)

                    // Restore
                    Button {
                        Task {
                            await store.restorePurchases()
                            if store.isPurchased {
                                profile?.isPremium = true
                                try? modelContext.save()
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Restore Purchase")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                    }

                    // Dismiss
                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textTertiary)
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.kaizenTeal)
                .frame(width: 36, height: 36)
                .background(Color.kaizenTeal.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.kaizenTeal)
        }
    }
}

#Preview {
    PaywallView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
