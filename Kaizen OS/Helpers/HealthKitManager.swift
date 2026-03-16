//
//  HealthKitManager.swift
//  Kaizen OS
//
//  Premium feature: auto-imports sleep, steps, and wake time from Apple Health.
//  Requires HealthKit capability in Signing & Capabilities (manual Xcode step).
//

import Foundation
import HealthKit

struct HealthSnapshot {
    var sleepHours: Double?
    var wakeTime: Date?
    var steps: Int?
}

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    private let store = HKHealthStore()

    /// Requests HealthKit permission and returns today's snapshot.
    func fetchTodayHealth() async -> HealthSnapshot {
        guard isAvailable else { return HealthSnapshot() }

        let typesToRead: Set<HKObjectType> = [
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.stepCount),
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            return HealthSnapshot()
        }

        async let sleepHours = fetchSleepHours()
        async let wakeTime = fetchWakeTime()
        async let steps = fetchSteps()

        return await HealthSnapshot(sleepHours: sleepHours, wakeTime: wakeTime, steps: steps)
    }

    // MARK: - Private fetchers

    private func fetchSleepHours() async -> Double? {
        let type = HKCategoryType(.sleepAnalysis)
        let today = Calendar.current.startOfDay(for: Date())
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let asleep = (samples as? [HKCategorySample])?.filter {
                    $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                    || $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                    || $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                } ?? []
                let totalSeconds = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: totalSeconds > 0 ? totalSeconds / 3600 : nil)
            }
            store.execute(query)
        }
    }

    private func fetchWakeTime() async -> Date? {
        let type = HKCategoryType(.sleepAnalysis)
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                continuation.resume(returning: (samples?.first as? HKCategorySample)?.endDate)
            }
            store.execute(query)
        }
    }

    private func fetchSteps() async -> Int? {
        let type = HKQuantityType(.stepCount)
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                if let steps = stats?.sumQuantity()?.doubleValue(for: .count()) {
                    continuation.resume(returning: Int(steps))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }
    }
}
