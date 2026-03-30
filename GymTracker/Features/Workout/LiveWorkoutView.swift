import Observation
import SwiftUI

struct LiveWorkoutView: View {
    @Bindable var sessionManager: WorkoutSessionManager
    let exerciseName: String

    @State private var coach = FormCoachService()

    var body: some View {
        VStack(spacing: 0) {
            // Top: exercise name + rep count
            HStack(alignment: .firstTextBaseline) {
                CoachHeader(
                    exerciseName: exerciseName,
                    providerName: coach.providerState.rawValue,
                    providerStatus: coach.providerStatus,
                    providerTint: providerTint
                )

                Spacer()

                Text("\(sessionManager.repCount)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Camera with coaching cue overlay
            ZStack(alignment: .bottom) {
                CameraStageView(sessionManager: sessionManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let cue = coach.coachingCue {
                    Text(cue)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.bottom, 14)
                        .padding(.horizontal, 14)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 18)
            .animation(.easeInOut(duration: 0.3), value: coach.coachingCue)

            // Bottom: status pills + recalibrate
            HStack(spacing: 8) {
                StatusPill(title: lockLabel, value: "", tint: lockTint)
                StatusPill(title: formLabel, value: "", tint: formTint)
                Spacer()
                Button(action: sessionManager.recalibrate) {
                    Text("Recalibrate")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.surface)
                        .clipShape(Capsule())
                }
                .tint(AppTheme.danger)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .onAppear {
            coach.refreshAvailability()
            refreshCoach()
        }
        .onChange(of: sessionManager.formMessage) { _, _ in refreshCoach() }
        .onChange(of: sessionManager.formStatus) { _, _ in refreshCoach() }
        .onChange(of: sessionManager.formPrimaryMetric) { _, _ in refreshCoach() }
        .onChange(of: sessionManager.formFailedRules) { _, _ in refreshCoach() }
        .onChange(of: coach.coachingCue) { _, cue in
            sessionManager.announceCoachingCue(cue)
        }
    }

    private var providerTint: Color {
        switch coach.providerState {
        case .anthropic:
            AppTheme.warning
        case .foundationModels:
            AppTheme.success
        case .deterministic:
            AppTheme.gymDim
        }
    }

    private var lockTint: Color {
        switch sessionManager.trackingStatus {
        case .locked:                    AppTheme.success
        case .reacquiring, .calibrating: AppTheme.warning
        case .lost:                      AppTheme.danger
        }
    }

    private var formTint: Color {
        switch sessionManager.formStatus {
        case .good:             AppTheme.success
        case .ready, .caution:  AppTheme.warning
        case .invalid, .paused: AppTheme.danger
        }
    }

    private var lockLabel: String {
        switch sessionManager.trackingStatus {
        case .locked:       "Locked"
        case .reacquiring:  "Recovering"
        case .calibrating:  "Calibrating"
        case .lost:         "Lost"
        }
    }

    private var formLabel: String {
        switch sessionManager.formStatus {
        case .good:    "Good"
        case .ready:   "Ready"
        case .caution: "Caution"
        case .invalid: "Invalid"
        case .paused:  "Paused"
        }
    }

    private func refreshCoach() {
        coach.update(
            exercise: exerciseName,
            status: sessionManager.formStatus,
            issue: sessionManager.formMessage,
            primaryMetric: sessionManager.formPrimaryMetric,
            failedRules: sessionManager.formFailedRules
        )
    }
}

private struct CoachHeader: View {
    let exerciseName: String
    let providerName: String
    let providerStatus: String
    let providerTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exerciseName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 8) {
                Text(providerName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(providerTint)
                    .clipShape(Capsule())

                Text(providerStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.gymSubtext)
                    .lineLimit(1)
            }
        }
    }
}
