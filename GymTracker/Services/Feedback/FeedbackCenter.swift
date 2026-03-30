import Foundation

final class FeedbackCenter {
    private let configuration: AppConfiguration

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    func resolveBanner(
        setupWarnings: [String],
        screen: SessionScreen,
        calibration: CalibrationSnapshot,
        trackingStatus: TrackingStatus,
        trackingMessage: String,
        visibility: VisibilityAssessment,
        exerciseState: StableExerciseState,
        analysis: ExerciseFrameAnalysis?,
        repCounter: RepCounterSnapshot
    ) -> FeedbackBanner? {
        if let setupWarning = setupWarnings.first {
            return FeedbackBanner(text: setupWarning, style: .critical, showsLessonAction: false)
        }

        if screen == .calibration {
            if calibration.onlyOneUserWarning {
                return FeedbackBanner(text: "Only one user should make the X gesture", style: .critical, showsLessonAction: false)
            }
            return FeedbackBanner(text: calibration.message, style: .warning, showsLessonAction: false)
        }

        switch trackingStatus {
        case .lost:
            return FeedbackBanner(text: trackingMessage, style: .critical, showsLessonAction: false)
        case .reacquiring:
            return FeedbackBanner(text: trackingMessage, style: .warning, showsLessonAction: false)
        case .calibrating:
            return FeedbackBanner(text: "Use Recalibrate to lock the right person", style: .warning, showsLessonAction: false)
        case .locked:
            break
        }

        guard visibility.isGoodEnough else {
            return FeedbackBanner(text: visibility.message, style: .warning, showsLessonAction: false)
        }

        if repCounter.lastRepWasInvalid {
            if repCounter.invalidAttemptStreak >= configuration.feedback.lessonPromptInvalidStreak {
                return FeedbackBanner(
                    text: "Your form looks incorrect. Please check the lesson again.",
                    style: .critical,
                    showsLessonAction: true
                )
            }

            return FeedbackBanner(
                text: repCounter.eventMessage ?? "Bad form detected — rep not counted",
                style: .critical,
                showsLessonAction: false
            )
        }

        if repCounter.didCountRep {
            return FeedbackBanner(text: repCounter.eventMessage ?? "Valid rep counted", style: .success, showsLessonAction: false)
        }

        if !exerciseState.isStable {
            return FeedbackBanner(
                text: "Hold the movement so the exercise can be recognized",
                style: .warning,
                showsLessonAction: false
            )
        }

        if !exerciseState.isSupported {
            return FeedbackBanner(
                text: "\(exerciseState.displayName) detected. Form validation is not configured yet.",
                style: .warning,
                showsLessonAction: false
            )
        }

        if let analysis, !analysis.formPassed {
            return FeedbackBanner(
                text: analysis.cue ?? "Bad form detected — rep not counted",
                style: .critical,
                showsLessonAction: false
            )
        }

        if let analysis, analysis.formPassed {
            return FeedbackBanner(text: analysis.cue ?? "Good form", style: .success, showsLessonAction: false)
        }

        return nil
    }
}
