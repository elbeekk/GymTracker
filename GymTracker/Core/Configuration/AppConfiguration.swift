import Foundation

struct AppConfiguration: Sendable {
    struct Camera: Sendable {
        var useFrontCamera = true
        var mirrorPreview = true

        nonisolated init() {}
    }

    struct Pose: Sendable {
        var minimumPoseConfidence = 0.25
        var essentialKeypointConfidence = 0.45
        var minimumBoundingBoxArea = 0.035
        var maximumBodyHeightFraction = 0.92
        var minimumBodyHeightFraction = 0.20
        var edgeMargin = 0.02
        var targetFPS = 30.0
        var minimumFrameInterval: TimeInterval { 1.0 / targetFPS }

        nonisolated init() {}
    }

    struct Classification: Sendable {
        var modelName = "ExerciseClassifier"
        var minimumDisplayConfidence = 0.20
        var minimumAcceptedConfidence = 0.30
        var minimumStableFrames = 2
        var smoothingWindow = 6
        var classifyEveryNFrames = 1
        var minimumLockedFramesBeforeClassification = 1

        nonisolated init() {}
    }

    struct Tracking: Sendable {
        var calibrationStableFrames = 18
        var focusGestureStableFrames = 10
        var centerTolerance = 0.16
        var candidateSimilarityDistance = 0.08
        var matchThreshold = 0.58
        var hardJumpDistance = 0.28
        var lostFrameTolerance = 8

        nonisolated init() {}
    }

    struct RepCounting: Sendable {
        var minimumRepDuration: TimeInterval = 0.45
        var minimumBottomPause: TimeInterval = 0.05
        var movementVelocityThreshold = 10.0
        var smoothingAlpha = 0.35

        nonisolated init() {}
    }

    struct Feedback: Sendable {
        var lessonPromptInvalidStreak = 3

        nonisolated init() {}
    }

    struct VoiceGuidance: Sendable {
        var isEnabled = true
        var speechRate: Float = 0.49
        var minimumRepeatInterval: TimeInterval = 4.0
        var minimumInterruptInterval: TimeInterval = 1.25

        nonisolated init() {}
    }

    struct Anthropic: Sendable {
        var endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
        // Cheapest current official Anthropic API model.
        var model = "claude-3-haiku-20240307"
        var apiVersion = "2023-06-01"
        var maxTokens = 32
        var temperature = 0.1
        var apiKeyEnvironmentVariable = "ANTHROPIC_API_KEY"
        var apiKeyInfoDictionaryKey = "ANTHROPIC_API_KEY"

        nonisolated init() {}

        var apiKey: String? {
            if
                let environmentValue = ProcessInfo.processInfo.environment[apiKeyEnvironmentVariable]?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !environmentValue.isEmpty
            {
                return environmentValue
            }

            if
                let infoValue = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoDictionaryKey) as? String,
                !infoValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                return infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if
                let storedValue = AnthropicKeychainStore().load(),
                !storedValue.isEmpty
            {
                return storedValue
            }

            return nil
        }
    }

    var camera = Camera()
    var pose = Pose()
    var classification = Classification()
    var tracking = Tracking()
    var repCounting = RepCounting()
    var feedback = Feedback()
    var voiceGuidance = VoiceGuidance()
    var anthropic = Anthropic()

    nonisolated init() {}

    static let production = AppConfiguration()
}
