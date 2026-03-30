import SwiftUI

struct CameraStageView: View {
    let sessionManager: WorkoutSessionManager

    var body: some View {
        ZStack {
            CameraPreviewView(
                session: sessionManager.cameraSession,
                isMirrored: sessionManager.isPreviewMirrored
            )

            LinearGradient(
                colors: [.black.opacity(0.02), .black.opacity(0.08), .black.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )

            SkeletonOverlayView(
                overlay: sessionManager.overlay,
                isMirrored: sessionManager.isPreviewMirrored
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}
