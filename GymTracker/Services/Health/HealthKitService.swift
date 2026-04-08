import Foundation
import HealthKit

final class HealthKitService {
    private let healthStore = HKHealthStore()
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
    private var didRequestAuthorization = false

    func requestActiveEnergyAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable(), !didRequestAuthorization, let activeEnergyType else { return }
        didRequestAuthorization = true

        do {
            try await requestAuthorization(readTypes: [activeEnergyType])
        } catch {
            // Keep the existing in-app fallback path when HealthKit is unavailable or denied.
        }
    }

    func activeEnergyBurnedKilocalories(start: Date, end: Date) async -> Double? {
        guard HKHealthStore.isHealthDataAvailable(), let activeEnergyType else { return nil }

        await requestActiveEnergyAuthorizationIfNeeded()

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: [.strictStartDate, .strictEndDate]
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let kilocalories = statistics?
                    .sumQuantity()?
                    .doubleValue(for: .kilocalorie())
                continuation.resume(returning: kilocalories)
            }

            healthStore.execute(query)
        }
    }

    private func requestAuthorization(readTypes: Set<HKObjectType>) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                }
            }
        }
    }
}

private enum HealthKitError: Error {
    case authorizationDenied
}
