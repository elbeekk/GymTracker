import Observation
import SwiftUI

struct CalibrationView: View {
    @Bindable var sessionManager: WorkoutSessionManager

    var body: some View {
        VStack(spacing: 0) {
            // Title + progress
            HStack(alignment: .firstTextBaseline) {
                Text("Make an X")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Spacer()

                Text("\(Int(sessionManager.calibrationProgress.clamped(to: 0...1) * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.info)
                    .monospacedDigit()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Camera fills remaining space
            CameraStageView(sessionManager: sessionManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 18)

            // Bottom: status + reset
            HStack(spacing: 8) {
                StatusPill(title: visibilityLabel, value: "", tint: visibilityTint)
                Spacer()
                Button(action: sessionManager.recalibrate) {
                    Text("Reset")
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
    }

    private var visibilityLabel: String {
        switch sessionManager.visibilityAssessment.status {
        case .fullBody:      "Visible"
        case .partial:       "Adjust"
        case .tooClose:      "Too Close"
        case .lowConfidence: "Unclear"
        case .notVisible:    "Missing"
        }
    }

    private var visibilityTint: Color {
        switch sessionManager.visibilityAssessment.status {
        case .fullBody:                           AppTheme.success
        case .partial, .tooClose, .lowConfidence: AppTheme.warning
        case .notVisible:                         AppTheme.danger
        }
    }
}
