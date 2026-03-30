import Foundation

struct WorkoutEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let exerciseName: String
    let categoryName: String
    let repCount: Int
    let durationSeconds: Int
    let caloriesBurned: Double

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseName: String,
        categoryName: String,
        repCount: Int,
        durationSeconds: Int,
        caloriesBurned: Double
    ) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.categoryName = categoryName
        self.repCount = repCount
        self.durationSeconds = durationSeconds
        self.caloriesBurned = caloriesBurned
    }

    var formattedDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}
