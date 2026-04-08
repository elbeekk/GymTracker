import CoreVideo
import Foundation

final class WorkoutFrameProcessor {
    let processingQueue = DispatchQueue(label: "gymtracker.frame.processor", qos: .userInitiated)
    var onSnapshot: ((WorkoutPipelineSnapshot) -> Void)?

    private let configuration: AppConfiguration
    private let poseEstimator: any PoseEstimating
    private let classifier: any ExerciseClassifying
    private let visibilityValidator: BodyVisibilityValidator
    private let tracker: PersonLockingTracker
    private let formAnalyzer: FormAnalyzer
    private let repCounter: RepCounter
    private let feedbackCenter: FeedbackCenter
    private let exerciseStabilizer: ExerciseStabilizer
    private let setupWarnings: [String]
    private let fixedExercise: ExerciseType?

    private var currentScreen: SessionScreen = .calibration
    private var currentStableLabel: String?
    private var frameIndex = 0
    private var lastProcessedTimestamp: TimeInterval = 0

    init(
        configuration: AppConfiguration,
        poseEstimator: any PoseEstimating,
        classifier: any ExerciseClassifying,
        fixedExercise: ExerciseType? = nil
    ) {
        self.configuration = configuration
        self.poseEstimator = poseEstimator
        self.classifier = classifier
        self.fixedExercise = fixedExercise
        self.visibilityValidator = BodyVisibilityValidator(configuration: configuration)
        self.tracker = PersonLockingTracker(configuration: configuration, visibilityValidator: visibilityValidator)
        self.formAnalyzer = FormAnalyzer(configuration: configuration)
        self.repCounter = RepCounter(configuration: configuration)
        self.feedbackCenter = FeedbackCenter(configuration: configuration)
        self.exerciseStabilizer = ExerciseStabilizer(configuration: configuration)
        self.setupWarnings = [poseEstimator.setupMessage, classifier.setupMessage].compactMap { $0 }
    }

    func recalibrate() {
        processingQueue.async {
            self.currentScreen = .calibration
            self.currentStableLabel = nil
            self.tracker.reset()
            self.formAnalyzer.reset()
            self.repCounter.resetForNewExercise()
            self.exerciseStabilizer.reset()
            self.classifier.reset()
            self.emitSnapshot(.initial(setupWarnings: self.setupWarnings))
        }
    }

    func consume(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) {
        guard timestamp - lastProcessedTimestamp >= configuration.pose.minimumFrameInterval else { return }
        lastProcessedTimestamp = timestamp
        frameIndex += 1

        do {
            let poses = try poseEstimator.estimatePoses(in: pixelBuffer)
            if tracker.hasLock && currentScreen == .live {
                processLiveFrame(poses: poses, timestamp: timestamp)
            } else {
                processCalibrationFrame(poses: poses, timestamp: timestamp)
            }
        } catch {
            let snapshot = WorkoutPipelineSnapshot(
                screen: currentScreen,
                overlay: .empty,
                exerciseState: exerciseStabilizer.currentState,
                repCounter: .initial,
                formStatus: .paused,
                formMessage: "Inference error",
                formPrimaryMetric: nil,
                formFailedRules: [],
                trackingStatus: tracker.hasLock ? .lost : .calibrating,
                trackingMessage: error.localizedDescription,
                visibilityAssessment: .unavailable,
                feedbackBanner: FeedbackBanner(text: error.localizedDescription, style: .critical, showsLessonAction: false),
                calibration: .initial,
                setupWarnings: setupWarnings
            )
            emitSnapshot(snapshot)
        }
    }

    private func processCalibrationFrame(poses: [PosePerson], timestamp: TimeInterval) {
        let calibrationResult = tracker.evaluateCalibration(poses: poses)

        if calibrationResult.snapshot.canLock, tracker.lockCurrentCandidate(at: timestamp) {
            currentScreen = .live
            currentStableLabel = nil
            exerciseStabilizer.reset()
            formAnalyzer.reset()
            repCounter.resetForNewExercise()
            classifier.reset()

            let overlay = overlayState(
                poses: poses,
                highlightedCandidateID: nil,
                trackedID: calibrationResult.candidatePose?.id,
                trackingStatus: .locked,
                showCalibrationGuide: false
            )

            let snapshot = WorkoutPipelineSnapshot(
                screen: .live,
                overlay: overlay,
                exerciseState: .idle,
                repCounter: .initial,
                formStatus: .ready,
                formMessage: "User locked. Start when ready.",
                formPrimaryMetric: nil,
                formFailedRules: [],
                trackingStatus: .locked,
                trackingMessage: "Locked on current user",
                visibilityAssessment: calibrationResult.candidatePose.map(visibilityValidator.assess(_:)) ?? .unavailable,
                feedbackBanner: FeedbackBanner(text: "User locked. Start the set when ready.", style: .success, showsLessonAction: false),
                calibration: calibrationResult.snapshot,
                setupWarnings: setupWarnings
            )
            emitSnapshot(snapshot)
            return
        }

        let overlay = overlayState(
            poses: poses,
            highlightedCandidateID: calibrationResult.snapshot.candidateID,
            trackedID: nil,
            trackingStatus: .calibrating,
            showCalibrationGuide: true
        )

        let visibility = calibrationResult.candidatePose.map(visibilityValidator.assess(_:)) ?? .unavailable
        let feedback = feedbackCenter.resolveBanner(
            setupWarnings: setupWarnings,
            screen: .calibration,
            calibration: calibrationResult.snapshot,
            trackingStatus: .calibrating,
            trackingMessage: calibrationResult.snapshot.message,
            visibility: visibility,
            exerciseState: .idle,
            analysis: nil,
            repCounter: .initial
        )

        emitSnapshot(
            WorkoutPipelineSnapshot(
                screen: .calibration,
                overlay: overlay,
                exerciseState: .idle,
                repCounter: .initial,
                formStatus: .paused,
                formMessage: calibrationResult.snapshot.message,
                formPrimaryMetric: nil,
                formFailedRules: [],
                trackingStatus: .calibrating,
                trackingMessage: calibrationResult.snapshot.message,
                visibilityAssessment: visibility,
                feedbackBanner: feedback,
                calibration: calibrationResult.snapshot,
                setupWarnings: setupWarnings
            )
        )
    }

    private func processLiveFrame(poses: [PosePerson], timestamp: TimeInterval) {
        let trackingUpdate = tracker.update(with: poses, timestamp: timestamp)
        let visibility = trackingUpdate.trackedPose.map(visibilityValidator.assess(_:)) ?? .unavailable

        if trackingUpdate.status == .lost {
            classifier.reset()
            formAnalyzer.reset()
            repCounter.pause()
        }

        let exerciseState = resolveExerciseState(trackingUpdate: trackingUpdate, visibility: visibility)
        if exerciseState.stableLabel != currentStableLabel {
            currentStableLabel = exerciseState.stableLabel
            formAnalyzer.reset()
            repCounter.resetForNewExercise()
        }

        let analysis: ExerciseFrameAnalysis? = {
            guard
                let trackedPose = trackingUpdate.trackedPose,
                trackingUpdate.status == .locked,
                exerciseState.isStable,
                exerciseState.isSupported,
                exerciseState.confidence >= configuration.classification.minimumAcceptedConfidence
            else {
                return nil
            }

            return formAnalyzer.analyze(
                exercise: exerciseState.stableExercise,
                pose: trackedPose,
                timestamp: timestamp
            )
        }()

        let repSnapshot = repCounter.process(
            analysis: analysis,
            gating: RepGatingContext(
                trackingLocked: trackingUpdate.status == .locked,
                fullBodyVisible: visibility.isGoodEnough,
                classificationStable: exerciseState.isStable,
                classificationConfidenceGood: exerciseState.confidence >= configuration.classification.minimumAcceptedConfidence,
                poseConfidenceGood: (analysis?.poseConfidence ?? trackingUpdate.trackedPose?.overallConfidence ?? 0) >= configuration.pose.minimumPoseConfidence
            ),
            timestamp: timestamp
        )

        let overlay = overlayState(
            poses: poses,
            highlightedCandidateID: nil,
            trackedID: trackingUpdate.trackedPose?.id,
            trackingStatus: trackingUpdate.status,
            showCalibrationGuide: false
        )

        let formPresentation = resolveFormPresentation(
            trackingStatus: trackingUpdate.status,
            visibility: visibility,
            exerciseState: exerciseState,
            analysis: analysis
        )

        let feedback = feedbackCenter.resolveBanner(
            setupWarnings: setupWarnings,
            screen: .live,
            calibration: .initial,
            trackingStatus: trackingUpdate.status,
            trackingMessage: trackingUpdate.message,
            visibility: visibility,
            exerciseState: exerciseState,
            analysis: analysis,
            repCounter: repSnapshot
        )

        emitSnapshot(
            WorkoutPipelineSnapshot(
                screen: .live,
                overlay: overlay,
                exerciseState: exerciseState,
                repCounter: repSnapshot,
                formStatus: formPresentation.status,
                formMessage: formPresentation.message,
                formPrimaryMetric: analysis?.primaryMetric,
                formFailedRules: analysis?.failedRules ?? [],
                trackingStatus: trackingUpdate.status,
                trackingMessage: trackingUpdate.message,
                visibilityAssessment: visibility,
                feedbackBanner: feedback,
                calibration: .initial,
                setupWarnings: setupWarnings
            )
        )
    }

    private func resolveExerciseState(
        trackingUpdate: TrackingUpdate,
        visibility: VisibilityAssessment
    ) -> StableExerciseState {
        // If the user chose a specific exercise, always skip ML classification.
        if let fixed = fixedExercise {
            return StableExerciseState(
                rawClassification: ExerciseClassification(exercise: fixed, confidence: 1.0, rawLabel: fixed.rawValue),
                stableExercise: fixed,
                stableLabel: fixed.rawValue,
                confidence: 1.0,
                stableFrames: 999,
                isStable: true
            )
        }

        guard
            trackingUpdate.status == .locked,
            visibility.isGoodEnough,
            let trackedPose = trackingUpdate.trackedPose,
            frameIndex >= configuration.classification.minimumLockedFramesBeforeClassification
        else {
            return exerciseStabilizer.currentState
        }

        guard frameIndex % configuration.classification.classifyEveryNFrames == 0 else {
            return exerciseStabilizer.currentState
        }

        let classification = (try? classifier.classify(pose: trackedPose)) ?? .unknown
        return exerciseStabilizer.update(with: classification)
    }

    private func resolveFormPresentation(
        trackingStatus: TrackingStatus,
        visibility: VisibilityAssessment,
        exerciseState: StableExerciseState,
        analysis: ExerciseFrameAnalysis?
    ) -> (status: FormStatus, message: String) {
        switch trackingStatus {
        case .lost:
            return (.paused, "Tracking lost — return to position")
        case .reacquiring:
            return (.caution, "Tracking unstable — hold position")
        case .calibrating:
            return (.paused, "Calibrate to begin")
        case .locked:
            break
        }

        guard exerciseState.isStable else {
            return (.caution, "Exercise recognition stabilizing")
        }

        guard exerciseState.isSupported else {
            return (.paused, "AI form tracking is not available for this exercise")
        }

        if let analysis {
            guard analysis.isSupported else {
                return (.paused, analysis.cue ?? visibility.message)
            }

            if analysis.formPassed {
                return (.good, analysis.cue ?? "Good form")
            } else {
                return (.invalid, analysis.cue ?? "Bad form detected")
            }
        }

        guard visibility.isGoodEnough else {
            return (.paused, visibility.message)
        }

        return (.ready, "Get into the start position")
    }

    private func overlayState(
        poses: [PosePerson],
        highlightedCandidateID: UUID?,
        trackedID: UUID?,
        trackingStatus: TrackingStatus,
        showCalibrationGuide: Bool
    ) -> SkeletonOverlayState {
        let renderablePeople = poses.map { pose in
            let role: OverlayPersonRole
            if let trackedID, pose.id == trackedID {
                role = trackingStatus == .lost ? .lost : .locked
            } else if let highlightedCandidateID, pose.id == highlightedCandidateID {
                role = .calibrationCandidate
            } else {
                role = .other
            }

            return OverlayRenderablePerson(
                id: pose.id,
                role: role,
                points: pose.allKeypoints,
                boundingBox: pose.boundingBox
            )
        }

        return SkeletonOverlayState(people: renderablePeople, showCalibrationGuide: showCalibrationGuide)
    }

    private func emitSnapshot(_ snapshot: WorkoutPipelineSnapshot) {
        onSnapshot?(snapshot)
    }
}

private final class ExerciseStabilizer {
    private let configuration: AppConfiguration
    private var history: [ExerciseClassification] = []
    private var streakLabelKey = ""
    private var stableFrames = 0

    private(set) var currentState: StableExerciseState = .idle

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    func reset() {
        history.removeAll()
        streakLabelKey = ""
        stableFrames = 0
        currentState = .idle
    }

    func update(with classification: ExerciseClassification) -> StableExerciseState {
        history.append(classification)
        if history.count > configuration.classification.smoothingWindow {
            history.removeFirst(history.count - configuration.classification.smoothingWindow)
        }

        let grouped = Dictionary(grouping: history.filter {
            $0.confidence >= configuration.classification.minimumDisplayConfidence &&
                !ExerciseType.normalizedLabelKey(from: $0.rawLabel).isEmpty &&
                $0.rawLabel.lowercased() != "unknown"
        }, by: { ExerciseType.normalizedLabelKey(from: $0.rawLabel) })

        let winner = grouped.max { lhs, rhs in
            score(for: lhs.value) < score(for: rhs.value)
        }

        let leadingLabelKey = winner?.key ?? ""
        let leadingLabel = winner?.value
            .max(by: { $0.confidence < $1.confidence })?
            .rawLabel
        let leadingExercise = ExerciseType(rawLabel: leadingLabel ?? "")
        let leadingConfidence = winner.map { averageConfidence(for: $0.value) } ?? 0

        if leadingLabelKey.isEmpty {
            streakLabelKey = ""
            stableFrames = 0
        } else if leadingLabelKey == streakLabelKey {
            stableFrames += 1
        } else {
            streakLabelKey = leadingLabelKey
            stableFrames = 1
        }

        let isStable = !leadingLabelKey.isEmpty &&
            leadingConfidence >= configuration.classification.minimumDisplayConfidence &&
            stableFrames >= configuration.classification.minimumStableFrames

        currentState = StableExerciseState(
            rawClassification: classification,
            stableExercise: isStable ? leadingExercise : .unknown,
            stableLabel: isStable ? leadingLabel : nil,
            confidence: leadingConfidence,
            stableFrames: stableFrames,
            isStable: isStable
        )

        return currentState
    }

    private func averageConfidence(for classifications: [ExerciseClassification]) -> Double {
        classifications.map(\.confidence).reduce(0, +) / Double(max(classifications.count, 1))
    }

    private func score(for classifications: [ExerciseClassification]) -> Double {
        averageConfidence(for: classifications) * Double(classifications.count)
    }
}
