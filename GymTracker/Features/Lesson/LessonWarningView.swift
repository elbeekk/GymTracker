import Observation
import SwiftUI

struct LessonWarningView: View {
    @Bindable var sessionManager: WorkoutSessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(AppTheme.tertiaryText.opacity(0.4))
                .frame(width: 42, height: 6)
                .frame(maxWidth: .infinity)

            Text("Review Form Before Continuing")
                .font(.title.weight(.bold))
                .foregroundStyle(Color.primary)

            Text(
                sessionManager.feedbackBanner?.text ??
                    "Please review the movement lesson before starting another set."
            )
            .font(.body)
            .foregroundStyle(AppTheme.secondaryText)

            VStack(alignment: .leading, spacing: 10) {
                Text("Suggested reset")
                    .font(.headline.weight(.semibold))
                Text("1. Rewatch the tutorial or lesson cues.")
                Text("2. Recalibrate so the app locks onto the same user again.")
                Text("3. Restart only when the full body is visible and the start position is clean.")
            }
            .foregroundStyle(AppTheme.secondaryText)

            HStack(spacing: 12) {
                Button("Not Now") {
                    sessionManager.dismissLessonSheet()
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)

                Button("Open Lesson") {
                    sessionManager.launchLessonFlow()
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
            }
        }
        .padding(24)
        .background(AppTheme.elevatedSurface)
    }
}
