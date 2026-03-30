import SwiftUI

struct HomeView: View {
    @Bindable var workoutStore: WorkoutStore
    let onStartWorkout: () -> Void

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }

    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    calendarSection
                    statsSection
                    startWorkoutCTA
                    recentWorkoutsSection
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateString)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.gymSubtext)
            Text("Today's Training")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.gymText)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        CalendarStripView(activeDates: workoutStore.activeDates())
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                value: String(format: "%.0f", workoutStore.totalCaloriesToday),
                unit: "kcal",
                label: "Calories"
            )
            StatCard(
                value: "\(workoutStore.totalRepsToday)",
                unit: "reps",
                label: "Total Reps"
            )
            StatCard(
                value: "\(workoutStore.totalMinutesToday)",
                unit: "min",
                label: "Active"
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Start Workout CTA

    private var startWorkoutCTA: some View {
        Button(action: onStartWorkout) {
            HStack {
                Text("Start Workout")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.gymBg)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.gymBg)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(AppTheme.gymText)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    // MARK: - Recent Workouts

    @ViewBuilder
    private var recentWorkoutsSection: some View {
        let recent = Array(workoutStore.entries.prefix(5))
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.gymSubtext)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 20)

                VStack(spacing: 1) {
                    ForEach(recent) { entry in
                        RecentWorkoutRow(entry: entry)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Subviews

private struct StatCard: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.gymText)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.gymSubtext)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.gymSubtext)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.gymSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecentWorkoutRow: View {
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
        .padding(.vertical, 12)
        Divider()
            .background(AppTheme.gymBorder)
    }
}
