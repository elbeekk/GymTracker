import SwiftUI

struct CalendarStripView: View {
    let activeDates: Set<DateComponents>
    var anchorDate: Date = Date()
    var selectedDate: Date? = nil
    var onSelect: ((Date) -> Void)? = nil

    private let calendar = Calendar.current
    private var weekDays: [Date] {
        let referenceDate = calendar.startOfDay(for: anchorDate)
        let weekday = calendar.component(.weekday, from: referenceDate)
        let startOffset = -(weekday - 2 + 7) % 7
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: startOffset + $0, to: referenceDate) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                DayCell(
                    date: day,
                    isToday: calendar.isDateInToday(day),
                    hasWorkout: hasWorkout(on: day),
                    isSelected: isSelected(day),
                    onTap: onSelect.map { handler in { handler(day) } }
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func hasWorkout(on date: Date) -> Bool {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return activeDates.contains(comps)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate else { return false }
        return calendar.isDate(selectedDate, inSameDayAs: date)
    }
}

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let hasWorkout: Bool
    let isSelected: Bool
    let onTap: (() -> Void)?

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
        let content = VStack(spacing: 8) {
            Text(dayLetter)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isFuture ? AppTheme.gymDim : AppTheme.gymSubtext)

            ZStack {
                if isSelected {
                    Circle()
                        .fill(AppTheme.gymAccent)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .stroke(AppTheme.gymText, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }
                Text(dayNumber)
                    .font(.system(size: 14, weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.gymBg : (isFuture ? AppTheme.gymDim : AppTheme.gymText))
            }

            Circle()
                .fill(hasWorkout ? AppTheme.gymAccent : Color.clear)
                .frame(width: 4, height: 4)
        }
        .padding(.vertical, 4)

        if let onTap {
            Button(action: onTap) {
                content
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}
