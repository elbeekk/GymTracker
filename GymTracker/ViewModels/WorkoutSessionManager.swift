import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class WorkoutSessionManager {
    let cameraSession: AVCaptureSession
    let isPreviewMirrored: Bool

    var screen: SessionScreen = .calibration
    var overlay: SkeletonOverlayState = .empty
    var exerciseDisplayName = ExerciseType.unknown.displayName
    var exerciseConfidence = 0.0
    var repCount = 0
    var repPhase: RepPhase = .idle
    var formStatus: FormStatus = .paused
    var formMessage = "Calibrate to begin"
    var formPrimaryMetric: Double? = nil
    var formFailedRules: [String] = []
    var trackingStatus: TrackingStatus = .calibrating
    var trackingMessage = "Show your full body and make an X with your arms"
    var visibilityAssessment: VisibilityAssessment = .unavailable
    var feedbackBanner: FeedbackBanner?
    var calibrationProgress = 0.0
    var setupWarnings: [String] = []
    var isLessonSheetPresented = false
    var cameraPermissionDenied = false

    private let configuration: AppConfiguration
    private let cameraManager: CameraManager
    private let processor: WorkoutFrameProcessor
    private let voiceGuidanceCoordinator: VoiceGuidanceCoordinator
    private var hasStarted = false
    private var lastSnapshot: WorkoutPipelineSnapshot?

    init(configuration: AppConfiguration = AppConfiguration(), fixedExercise: ExerciseType? = nil) {
        self.configuration = configuration

        let poseEstimator: any PoseEstimating = VisionPoseEstimatorService()

        let classifier: any ExerciseClassifying
        do {
            classifier = try CoreMLExerciseClassifierService(modelName: configuration.classification.modelName)
        } catch {
            classifier = UnavailableExerciseClassifierService(setupMessage: error.localizedDescription)
        }

        let processor = WorkoutFrameProcessor(
            configuration: configuration,
            poseEstimator: poseEstimator,
            classifier: classifier,
            fixedExercise: fixedExercise
        )
        let cameraManager = CameraManager(
            videoOutputQueue: processor.processingQueue,
            preferredPosition: configuration.camera.useFrontCamera ? .front : .back,
            previewMirrored: configuration.camera.mirrorPreview
        )
        let voiceGuidanceCoordinator = VoiceGuidanceCoordinator(configuration: configuration.voiceGuidance)

        self.processor = processor
        self.cameraManager = cameraManager
        self.voiceGuidanceCoordinator = voiceGuidanceCoordinator
        self.cameraSession = cameraManager.session
        self.isPreviewMirrored = cameraManager.isPreviewMirrored

        cameraManager.onFrame = { [weak processor] pixelBuffer, timestamp in
            processor?.consume(pixelBuffer: pixelBuffer, timestamp: timestamp)
        }

        processor.onSnapshot = { [weak self] snapshot in
            Task { @MainActor [weak self] in
                self?.apply(snapshot: snapshot)
            }
        }

        apply(snapshot: .initial(setupWarnings: [poseEstimator.setupMessage, classifier.setupMessage].compactMap { $0 }))
    }

    func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true

        let granted = await cameraManager.requestAccess()
        guard granted else {
            cameraPermissionDenied = true
            feedbackBanner = FeedbackBanner(
                text: "Camera access is required to analyze workouts and count reps.",
                style: .critical,
                showsLessonAction: false
            )
            voiceGuidanceCoordinator.announceSystemMessage(
                "Camera access is required to analyze workouts and count reps.",
                key: "camera-permission"
            )
            return
        }

        do {
            try await cameraManager.configureIfNeeded()
            cameraManager.startRunning()
        } catch {
            feedbackBanner = FeedbackBanner(
                text: error.localizedDescription,
                style: .critical,
                showsLessonAction: false
            )
            voiceGuidanceCoordinator.announceSystemMessage(error.localizedDescription, key: "camera-config-error")
        }
    }

    func recalibrate() {
        processor.recalibrate()
    }

    func announceCoachingCue(_ text: String?) {
        guard let text else { return }
        voiceGuidanceCoordinator.announceCoachingCue(text)
    }

    func openLessonSheet() {
        isLessonSheetPresented = true
    }

    func dismissLessonSheet() {
        isLessonSheetPresented = false
    }

    func launchLessonFlow() {
        // Hook this into your lesson/tutorial navigation when that module is added.
        isLessonSheetPresented = false
    }

    private func apply(snapshot: WorkoutPipelineSnapshot) {
        let previousSnapshot = lastSnapshot
        lastSnapshot = snapshot

        screen = snapshot.screen
        overlay = snapshot.overlay
        exerciseDisplayName = snapshot.exerciseState.displayName
        exerciseConfidence = snapshot.exerciseState.confidence
        repCount = snapshot.repCounter.repCount
        repPhase = snapshot.repCounter.phase
        formStatus = snapshot.formStatus
        formMessage = snapshot.formMessage
        formPrimaryMetric = snapshot.formPrimaryMetric
        formFailedRules = snapshot.formFailedRules
        trackingStatus = snapshot.trackingStatus
        trackingMessage = snapshot.trackingMessage
        visibilityAssessment = snapshot.visibilityAssessment
        feedbackBanner = snapshot.feedbackBanner
        calibrationProgress = snapshot.calibration.progress
        setupWarnings = snapshot.setupWarnings

        voiceGuidanceCoordinator.handle(snapshot: snapshot, previousSnapshot: previousSnapshot)
    }
}
