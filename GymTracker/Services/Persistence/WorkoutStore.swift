import Foundation
import Observation

@Observable
final class WorkoutStore {
    private(set) var entries: [WorkoutEntry] = []

    private let storageKey = "workout_entries_v1"

    init() {
        load()
    }

    func save(_ entry: WorkoutEntry) {
        entries.insert(entry, at: 0)
        persist()
    }

    // MARK: - Queries

    func entries(on date: Date) -> [WorkoutEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    func totalCalories(on date: Date) -> Double {
        entries(on: date).reduce(0) { $0 + $1.caloriesBurned }
    }

    func totalReps(on date: Date) -> Int {
        entries(on: date).reduce(0) { $0 + $1.repCount }
    }

    func totalMinutes(on date: Date) -> Int {
        entries(on: date).reduce(0) { $0 + $1.durationSeconds } / 60
    }

    var totalCaloriesToday: Double {
        totalCalories(on: Date())
    }

    var totalRepsToday: Int {
        totalReps(on: Date())
    }

    var totalMinutesToday: Int {
        totalMinutes(on: Date())
    }

    /// Returns all dates (in current calendar) that have at least one workout entry.
    func activeDates() -> Set<DateComponents> {
        let cal = Calendar.current
        return Set(entries.map { cal.dateComponents([.year, .month, .day], from: $0.date) })
    }

    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var day = Date()
        while true {
            let dayEntries = entries(on: day)
            if dayEntries.isEmpty { break }
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([WorkoutEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
