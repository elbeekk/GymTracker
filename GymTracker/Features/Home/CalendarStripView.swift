import SwiftUI

struct CalendarStripView: View {
    let activeDates: Set<DateComponents>

    private let calendar = Calendar.current
    private var weekDays: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOffset = -(weekday - 2 + 7) % 7
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: startOffset + $0, to: today) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                DayCell(
                    date: day,
                    isToday: calendar.isDateInToday(day),
                    hasWorkout: hasWorkout(on: day)
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func hasWorkout(on date: Date) -> Bool {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return activeDates.contains(comps)
    }
}

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let hasWorkout: Bool

    private let calendar = Calendar.current

    private var dayLetter: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return String(fmt.string(from: date).prefix(1))
    }

    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }

    private var isFuture: Bool {
        date > Date() && !calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(dayLetter)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isFuture ? AppTheme.gymDim : AppTheme.gymSubtext)

            ZStack {
                if isToday {
                    Circle()
                        .fill(AppTheme.gymText)
                        .frame(width: 32, height: 32)
                }
                Text(dayNumber)
                    .font(.system(size: 14, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? AppTheme.gymBg : (isFuture ? AppTheme.gymDim : AppTheme.gymText))
            }

            Circle()
                .fill(hasWorkout ? AppTheme.gymAccent : Color.clear)
                .frame(width: 4, height: 4)
        }
        .padding(.vertical, 4)
    }
}
