import SwiftUI

struct HistoryView: View {
    @Bindable var workoutStore: WorkoutStore

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var monthStart: Date {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return calendar.date(from: components) ?? displayedMonth
    }

    private var monthEntries: [WorkoutEntry] {
        workoutStore.entries.filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
    }

    private var selectedEntries: [WorkoutEntry] {
        guard let selectedDate else { return [] }
        return workoutStore.entries(on: selectedDate)
    }

    private var monthCalories: Double {
        monthEntries.reduce(0) { $0 + $1.caloriesBurned }
    }

    private var monthMinutes: Int {
        monthEntries.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var monthActiveDays: Int {
        Set(monthEntries.map { calendar.dateComponents([.year, .month, .day], from: $0.date) }).count
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var selectedDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate ?? displayedMonth)
    }

    private var canAdvanceMonth: Bool {
        monthStart < startOfMonth(for: Date())
    }

    private var calendarDays: [Date?] {
        let start = monthStart
        let dayRange = calendar.range(of: .day, in: .month, for: start) ?? 1 ..< 2
        let weekday = calendar.component(.weekday, from: start)
        let leadingSlots = (weekday - 2 + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingSlots)
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        })

        let trailingSlots = (7 - (days.count % 7)) % 7
        days.append(contentsOf: Array(repeating: nil, count: trailingSlots))
        return days
    }

    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    monthSummarySection
                    calendarSection
                    selectedDaySection
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            displayedMonth = startOfMonth(for: Date())
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("History")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.gymText)
            Text("Browse your workouts by month and day")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.gymSubtext)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }

    private var monthSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(monthLabel)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.gymText)
                Spacer()
                Text("\(monthEntries.count) workouts")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.gymSubtext)
            }

            HStack(spacing: 12) {
                MonthMetricCard(
                    title: "Active Days",
                    value: "\(monthActiveDays)",
                    tint: AppTheme.gymBlue
                )
                MonthMetricCard(
                    title: "Calories",
                    value: String(format: "%.0f", monthCalories),
                    tint: AppTheme.gymAccent
                )
                MonthMetricCard(
                    title: "Minutes",
                    value: "\(monthMinutes)",
                    tint: AppTheme.gymGreen
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button(action: showPreviousMonth) {
                    monthNavigationIcon("chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.gymText)

                Spacer()

                Button(action: showNextMonth) {
                    monthNavigationIcon("chevron.right", dimmed: !canAdvanceMonth)
                }
                .buttonStyle(.plain)
                .disabled(!canAdvanceMonth)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.gymSubtext)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        MonthDayButton(
                            date: date,
                            isToday: calendar.isDateInToday(date),
                            isSelected: selectedDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false,
                            workoutCount: workoutCount(on: date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 42)
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.gymSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if selectedDate != nil {
                Text(selectedDateLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.gymText)

                if selectedEntries.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(AppTheme.gymDim)
                        Text("No workouts on this date")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.gymText)
                        Text("Move to another day in the calendar to inspect your past sessions.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.gymSubtext)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .padding(.horizontal, 20)
                    .background(AppTheme.gymSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 1) {
                        ForEach(selectedEntries) { entry in
                            HistoryWorkoutRow(entry: entry)
                        }
                    }
                    .background(AppTheme.gymSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppTheme.gymDim)
                    Text("Select a day")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.gymText)
                    Text("Days with workouts show a count below the date. Tap any day to inspect its sessions.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gymSubtext)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .background(AppTheme.gymSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
    }

    private var weekdaySymbols: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
    }

    @ViewBuilder
    private func monthNavigationIcon(_ systemName: String, dimmed: Bool = false) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(dimmed ? AppTheme.gymDim : AppTheme.gymText)
            .frame(width: 36, height: 36)
            .background(AppTheme.gymCard)
            .clipShape(Circle())
    }

    private func workoutCount(on date: Date) -> Int {
        workoutStore.entries(on: date).count
    }

    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func showPreviousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
    }

    private func showNextMonth() {
        guard canAdvanceMonth else { return }
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
    }
}

private struct MonthMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(tint)
                .frame(width: 26, height: 4)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.gymText)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.gymSubtext)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.gymSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.gymBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct MonthDayButton: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let workoutCount: Int
    let action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.gymAccent)
                            .frame(width: 30, height: 30)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.gymText, lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                    }

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 13, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundStyle(isSelected ? AppTheme.gymBg : AppTheme.gymText)
                }

                if workoutCount > 0 {
                    Text("\(workoutCount)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.gymAccent)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct HistoryWorkoutRow: View {
    let entry: WorkoutEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.exerciseName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.gymText)
                Text("\(entry.repCount) reps · \(entry.formattedDuration)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.gymSubtext)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.0f kcal", entry.caloriesBurned))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.gymText)
                Text(entry.formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.gymSubtext)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    HistoryView(workoutStore: WorkoutStore())
}
