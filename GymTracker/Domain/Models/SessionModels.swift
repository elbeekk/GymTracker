import Foundation

enum SessionScreen: Sendable {
    case calibration
    case live
}

enum TrackingStatus: String, Sendable {
    case calibrating
    case locked
    case reacquiring
    case lost
}

enum VisibilityStatus: String, Sendable {
    case fullBody
    case partial
    case tooClose
    case lowConfidence
    case notVisible
}

enum FormStatus: String, Sendable {
    case ready
    case good
    case caution
    case invalid
    case paused
}

enum FeedbackStyle: Sendable {
    case success
    case warning
    case critical
    case neutral
}

struct ExerciseClassification: Sendable {
    let exercise: ExerciseType
    let confidence: Double
    let rawLabel: String

    static let unknown = ExerciseClassification(exercise: .unknown, confidence: 0, rawLabel: "unknown")
}

struct StableExerciseState: Sendable {
    let rawClassification: ExerciseClassification
    let stableExercise: ExerciseType
    let stableLabel: String?
    let confidence: Double
    let stableFrames: Int
    let isStable: Bool

    static let idle = StableExerciseState(
        rawClassification: .unknown,
        stableExercise: .unknown,
        stableLabel: nil,
        confidence: 0,
        stableFrames: 0,
        isStable: false
    )

    var displayName: String {
        guard isStable else { return ExerciseType.unknown.displayName }
        if stableExercise != .unknown {
            return stableExercise.displayName
        }
        return stableLabel.map(ExerciseType.displayName(forRawLabel:)) ?? ExerciseType.unknown.displayName
    }

    var isSupported: Bool {
        stableExercise != .unknown
    }
}

struct VisibilityAssessment: Sendable {
    let status: VisibilityStatus
    let message: String
    let score: Double
    let isGoodEnough: Bool

    static let unavailable = VisibilityAssessment(
        status: .notVisible,
        message: "Stand fully inside the frame",
        score: 0,
        isGoodEnough: false
    )
}

struct CalibrationSnapshot: Sendable {
    let progress: Double
    let canLock: Bool
    let candidateID: UUID?
    let message: String
    let onlyOneUserWarning: Bool

    static let initial = CalibrationSnapshot(
        progress: 0,
        canLock: false,
        candidateID: nil,
        message: "Show your full body and make an X with your arms",
        onlyOneUserWarning: false
    )
}

struct LockedPerson: Sendable {
    let id: UUID
    let referencePose: PosePerson
    var lastPose: PosePerson
    var lastSeenTimestamp: TimeInterval
    var missingFrameCount: Int
}

enum RepPhase: String, Sendable {
    case idle
    case ready
    case descending
    case bottom
    case ascending
}

struct RepCounterSnapshot: Sendable {
    let repCount: Int
    let phase: RepPhase
    let invalidAttemptStreak: Int
    let didCountRep: Bool
    let lastRepWasInvalid: Bool
    let eventMessage: String?

    static let initial = RepCounterSnapshot(
        repCount: 0,
        phase: .idle,
        invalidAttemptStreak: 0,
        didCountRep: false,
        lastRepWasInvalid: false,
        eventMessage: nil
    )
}

struct FeedbackBanner: Identifiable, Sendable {
    let id = UUID()
    let text: String
    let style: FeedbackStyle
    let showsLessonAction: Bool
}

enum OverlayPersonRole: Sendable {
    case locked
    case calibrationCandidate
    case other
    case lost
}

struct OverlayRenderablePerson: Identifiable, Sendable {
    let id: UUID
    let role: OverlayPersonRole
    let points: [PoseKeypoint]
    let boundingBox: CGRect
}

struct SkeletonOverlayState: Sendable {
    let people: [OverlayRenderablePerson]
    let showCalibrationGuide: Bool

    static let empty = SkeletonOverlayState(people: [], showCalibrationGuide: false)
}

struct WorkoutPipelineSnapshot: Sendable {
    let screen: SessionScreen
    let overlay: SkeletonOverlayState
    let exerciseState: StableExerciseState
    let repCounter: RepCounterSnapshot
    let formStatus: FormStatus
    let formMessage: String
    let formPrimaryMetric: Double?   // e.g. knee angle in degrees
    let formFailedRules: [String]    // e.g. ["Alignment", "Depth"]
    let trackingStatus: TrackingStatus
    let trackingMessage: String
    let visibilityAssessment: VisibilityAssessment
    let feedbackBanner: FeedbackBanner?
    let calibration: CalibrationSnapshot
    let setupWarnings: [String]

    static func initial(setupWarnings: [String] = []) -> WorkoutPipelineSnapshot {
        WorkoutPipelineSnapshot(
            screen: .calibration,
            overlay: .empty,
            exerciseState: .idle,
            repCounter: .initial,
            formStatus: .paused,
            formMessage: "Calibrate to begin",
            formPrimaryMetric: nil,
            formFailedRules: [],
            trackingStatus: .calibrating,
            trackingMessage: "Show your full body and make an X with your arms",
            visibilityAssessment: .unavailable,
            feedbackBanner: nil,
            calibration: .initial,
            setupWarnings: setupWarnings
        )
    }
}
