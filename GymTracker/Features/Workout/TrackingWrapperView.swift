import SwiftUI

struct TrackingWrapperView: View {
    let exercise: CatalogExercise
    let workoutStore: WorkoutStore
    let onFinish: () -> Void

    @State private var healthKit = HealthKitService()
    @State private var sessionManager: WorkoutSessionManager
    @State private var startTime = Date()
    @State private var showFinishConfirm = false
    @State private var isSavingWorkout = false

    init(exercise: CatalogExercise, workoutStore: WorkoutStore, onFinish: @escaping () -> Void) {
        self.exercise = exercise
        self.workoutStore = workoutStore
        self.onFinish = onFinish
        // Lock the session to the exercise the user chose — no ML auto-detection.
        // For exercises without an AI type we still pass a value to block the classifier.
        self._sessionManager = State(initialValue: WorkoutSessionManager(
            fixedExercise: exercise.exerciseType ?? .unknown
        ))
        // Note: passing .unknown tells the processor "skip classifier, but no form rules exist"
    }

    var body: some View {
        @Bindable var sessionManager = sessionManager

        ZStack(alignment: .top) {
            AppTheme.pageBackground.ignoresSafeArea()

            switch sessionManager.screen {
            case .calibration:
                CalibrationView(sessionManager: sessionManager)
            case .live:
                LiveWorkoutView(
                    sessionManager: sessionManager,
                    exerciseName: exercise.name
                )
            }

            // Finish button
            HStack {
                Spacer()
                Button(action: { showFinishConfirm = true }) {
                    Text("Finish")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.gymAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.trailing, 16)
                .padding(.top, 56)
            }
        }
        .task {
            await sessionManager.startIfNeeded()
            await healthKit.requestActiveEnergyAuthorizationIfNeeded()
        }
        .sheet(isPresented: $sessionManager.isLessonSheetPresented) {
            LessonWarningView(sessionManager: sessionManager)
                .presentationDetents([.fraction(0.38), .medium])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Finish Workout?",
            isPresented: $showFinishConfirm,
            titleVisibility: .visible
        ) {
            Button("Save & Finish") {
                guard !isSavingWorkout else { return }
                isSavingWorkout = true
                Task { await saveAndFinish() }
            }
            Button("Discard", role: .destructive) { onFinish() }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("\(sessionManager.repCount) reps completed")
        }
    }

    @MainActor
    private func saveAndFinish() async {
        let endTime = Date()
        let duration = Int(endTime.timeIntervalSince(startTime))
        let estimatedCalories = exercise.estimatedCaloriesPerMinute * Double(max(duration, 1)) / 60.0
        let calories = await healthKit.activeEnergyBurnedKilocalories(start: startTime, end: endTime) ?? estimatedCalories

        workoutStore.save(WorkoutEntry(
            exerciseName: exercise.name,
            categoryName: exercise.category.displayName,
            repCount: sessionManager.repCount,
            durationSeconds: duration,
            caloriesBurned: calories
        ))

        isSavingWorkout = false
        onFinish()
    }
}
