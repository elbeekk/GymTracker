import Foundation
import Observation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Uses Apple's on-device Foundation Models to turn raw form-rule violations
/// into short, body-part-specific coaching cues.
@MainActor
@Observable
final class FormCoachService {
    enum ProviderState: String {
        case anthropic = "Claude Haiku"
        case foundationModels = "On-Device AI"
        case deterministic = "Rule Coach"
    }

    private(set) var coachingCue: String? = nil
    private(set) var providerState: ProviderState = .deterministic
    private(set) var providerStatus = "Claude ready"

    private let configuration: AppConfiguration
    private let anthropicService: AnthropicCoachService
    private var lastRequestKey: String = ""
    private var currentTask: Task<Void, Never>? = nil
    private var keypointFrames: [[PoseKeypoint]] = []
    private let maxFrameBuffer = 20

    init(
        configuration: AppConfiguration? = nil,
        anthropicService: AnthropicCoachService? = nil
    ) {
        self.configuration = configuration ?? AppConfiguration()
        self.anthropicService = anthropicService ?? AnthropicCoachService()
        refreshAvailability()
    }

    /// Call each camera frame with the locked person's keypoints so Claude has movement history.
    func recordFrame(_ points: [PoseKeypoint]) {
        let filtered = points.filter { $0.confidence > 0.4 && !isFaceKeypoint($0.name) }
        guard !filtered.isEmpty else { return }
        keypointFrames.append(filtered)
        if keypointFrames.count > maxFrameBuffer {
            keypointFrames.removeFirst()
        }
    }

    /// Call this every time formStatus or formMessage changes.
    /// Only `.invalid` status triggers the AI — system/tracking messages use `.paused` or `.caution`.
    func update(
        exercise: String,
        status: FormStatus,
        issue: String,
        primaryMetric: Double?,
        failedRules: [String]
    ) {
        refreshAvailability()

        guard status == .invalid else {
            currentTask?.cancel()
            coachingCue = nil
            lastRequestKey = ""
            keypointFrames.removeAll()
            return
        }

        let normalizedIssue = issue.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRules = failedRules
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let requestKey = makeRequestKey(
            exercise: exercise,
            issue: normalizedIssue,
            primaryMetric: primaryMetric,
            failedRules: normalizedRules,
            remoteAvailable: configuration.anthropic.apiKey != nil
        )

        guard requestKey != lastRequestKey else { return }
        lastRequestKey = requestKey

        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.generateCue(
                exercise: exercise,
                issue: normalizedIssue,
                primaryMetric: primaryMetric,
                failedRules: normalizedRules
            )
            guard !Task.isCancelled else { return }
            self.providerState = result.provider
            self.providerStatus = result.status
            self.coachingCue = result.cue
        }
    }

    func refreshAvailability() {
        if configuration.anthropic.apiKey != nil {
            providerState = .anthropic
            providerStatus = "Claude ready"
        } else {
            providerState = .foundationModels
            providerStatus = "On-device AI active"
        }
    }

    // MARK: - Prompt

    private func generateCue(
        exercise: String,
        issue: String,
        primaryMetric: Double?,
        failedRules: [String]
    ) async -> CueResult {
        let fallback = fallbackCue(
            exercise: exercise,
            issue: issue,
            primaryMetric: primaryMetric,
            failedRules: failedRules
        )

        let prompt = buildPrompt(
            exercise: exercise,
            issue: issue,
            primaryMetric: primaryMetric,
            failedRules: failedRules
        )

        if let apiKey = configuration.anthropic.apiKey {
            do {
                let response = try await anthropicService.generateCue(
                    prompt: prompt,
                    configuration: configuration.anthropic,
                    apiKey: apiKey
                )
                return CueResult(
                    cue: validatedCue(from: response, fallback: fallback, rawIssue: issue),
                    provider: .anthropic,
                    status: "Claude live"
                )
            } catch {
                let onDeviceFallback = await generateLocalCue(prompt: prompt, fallback: fallback, rawIssue: issue)
                return CueResult(
                    cue: onDeviceFallback.cue,
                    provider: onDeviceFallback.provider,
                    status: "Claude unavailable using \(onDeviceFallback.provider.rawValue)"
                )
            }
        }

        let localResult = await generateLocalCue(prompt: prompt, fallback: fallback, rawIssue: issue)
        return CueResult(
            cue: localResult.cue,
            provider: localResult.provider,
            status: localResult.status
        )
    }

    private func generateLocalCue(prompt: String, fallback: String, rawIssue: String) async -> CueResult {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else {
                return CueResult(cue: fallback, provider: .deterministic, status: "Rule coach active")
            }
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                return CueResult(
                    cue: validatedCue(from: response.content, fallback: fallback, rawIssue: rawIssue),
                    provider: .foundationModels,
                    status: "On-device AI active"
                )
            } catch {
                return CueResult(cue: fallback, provider: .deterministic, status: "Rule coach active")
            }
        }
#endif
        return CueResult(cue: fallback, provider: .deterministic, status: "Rule coach active")
    }

    private func buildPrompt(
        exercise: String,
        issue: String,
        primaryMetric: Double?,
        failedRules: [String]
    ) -> String {
        let failedRulesLine = failedRules.isEmpty
            ? "Failed checks: none"
            : "Failed checks: \(failedRules.joined(separator: ", "))"

        let poseSection = keypointFramesSummary()

        return """
        Exercise: \(exercise)
        Form problem: \(issue.isEmpty ? "unspecified" : issue)
        \(failedRulesLine)
        \(metricLine(for: exercise, primaryMetric: primaryMetric))
        \(poseSection)

        Give 2-3 sentences of specific coaching corrections. Start with the most important fix.
        Name exact body parts (knees, elbows, hips, chest, etc.). Use plain gym language.
        Be direct and actionable. No bullet points.
        """
    }

    private func keypointFramesSummary() -> String {
        guard !keypointFrames.isEmpty else { return "Pose data: unavailable" }

        // Sample up to 6 evenly spaced frames from the buffer
        let total = keypointFrames.count
        let stride = max(1, total / 6)
        let sampled = Swift.stride(from: 0, to: total, by: stride).map { keypointFrames[$0] }

        let frameLines = sampled.enumerated().map { idx, points in
            let coords = points.compactMap { kp -> String? in
                let label = shortLabel(kp.name)
                return "\(label)(\(String(format: "%.2f", kp.location.x)),\(String(format: "%.2f", kp.location.y)))"
            }.joined(separator: " ")
            return "F\(idx + 1): \(coords)"
        }

        return "Pose sequence (\(sampled.count) frames, x/y normalized 0-1 from top-left):\n" + frameLines.joined(separator: "\n")
    }

    private func isFaceKeypoint(_ name: PoseKeypointName) -> Bool {
        switch name {
        case .nose, .leftEye, .rightEye, .leftEar, .rightEar: return true
        default: return false
        }
    }

    private func shortLabel(_ name: PoseKeypointName) -> String {
        switch name {
        case .nose: return "nose"
        case .leftEye: return "lEye"
        case .rightEye: return "rEye"
        case .leftEar: return "lEar"
        case .rightEar: return "rEar"
        case .leftShoulder: return "lSho"
        case .rightShoulder: return "rSho"
        case .leftElbow: return "lElb"
        case .rightElbow: return "rElb"
        case .leftWrist: return "lWri"
        case .rightWrist: return "rWri"
        case .leftHip: return "lHip"
        case .rightHip: return "rHip"
        case .leftKnee: return "lKne"
        case .rightKnee: return "rKne"
        case .leftAnkle: return "lAnk"
        case .rightAnkle: return "rAnk"
        }
    }

    private func relevantBodyParts(for exercise: String) -> String {
        switch exercise.lowercased() {
        case _ where exercise.localizedCaseInsensitiveContains("squat"):
            return "knees, hips, lower back, ankles, feet"
        case _ where exercise.localizedCaseInsensitiveContains("lunge"):
            return "front knee, back knee, hips, torso"
        case _ where exercise.localizedCaseInsensitiveContains("push"):
            return "elbows, chest, core, hips, back"
        case _ where exercise.localizedCaseInsensitiveContains("curl"):
            return "elbows, upper arms, wrists, torso"
        case _ where exercise.localizedCaseInsensitiveContains("press"):
            return "elbows, shoulders, wrists, lower back"
        case _ where exercise.localizedCaseInsensitiveContains("deadlift"):
            return "lower back, hips, hamstrings, shoulders"
        case _ where exercise.localizedCaseInsensitiveContains("row"):
            return "elbows, shoulder blades, back, hips"
        default:
            return "knees, hips, back, shoulders, arms"
        }
    }

    private func metricLine(for exercise: String, primaryMetric: Double?) -> String {
        guard let primaryMetric else {
            return "Primary measurement: unavailable"
        }

        return "Primary measurement: \(metricName(for: exercise)) is \(Int(primaryMetric.rounded())) degrees"
    }

    private func metricName(for exercise: String) -> String {
        switch exercise.lowercased() {
        case _ where exercise.localizedCaseInsensitiveContains("squat"):
            return "knee angle"
        case _ where exercise.localizedCaseInsensitiveContains("lunge"):
            return "front knee angle"
        case _ where exercise.localizedCaseInsensitiveContains("push"):
            return "elbow angle"
        case _ where exercise.localizedCaseInsensitiveContains("press"):
            return "elbow angle"
        case _ where exercise.localizedCaseInsensitiveContains("curl"):
            return "elbow angle"
        default:
            return "joint angle"
        }
    }

    private func makeRequestKey(
        exercise: String,
        issue: String,
        primaryMetric: Double?,
        failedRules: [String],
        remoteAvailable: Bool
    ) -> String {
        let metricBucket = primaryMetric.map { Int(($0 / 5).rounded()) * 5 }
        return [
            exercise.lowercased(),
            issue.lowercased(),
            failedRules.sorted().joined(separator: "|").lowercased(),
            metricBucket.map(String.init) ?? "nil",
            remoteAvailable ? "remote" : "local"
        ].joined(separator: "::")
    }

    private func validatedCue(from text: String, fallback: String, rawIssue: String) -> String {
        let normalized = normalizedCue(text)
        guard isUsableCue(normalized, rawIssue: rawIssue) else {
            return fallback
        }
        return normalized
    }

    private func normalizedCue(_ text: String) -> String {
        cleanedCue(text)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isUsableCue(_ cue: String, rawIssue: String) -> Bool {
        guard cue.split(separator: " ").count >= 3 else { return false }

        let normalizedCue = cue.lowercased()
        let normalizedIssue = rawIssue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let bannedPhrases = [
            "range of motion",
            "rep not counted",
            "invalid rep",
            "invalid",
            "tracking",
            "analysis",
            "metric",
            "tempo",
            "stability",
            "alignment"
        ]

        guard !bannedPhrases.contains(where: normalizedCue.contains) else {
            return false
        }

        if !normalizedIssue.isEmpty, normalizedCue == normalizedIssue {
            return false
        }

        return true
    }

    private func cleanedCue(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackCue(
        exercise: String,
        issue: String,
        primaryMetric: Double?,
        failedRules: [String]
    ) -> String {
        deterministicCue(
            exercise: exercise,
            issue: issue,
            primaryMetric: primaryMetric,
            failedRules: failedRules
        ) ?? defaultCue(for: exercise.lowercased())
    }

    private func deterministicCue(
        exercise: String,
        issue: String,
        primaryMetric: Double?,
        failedRules: [String]
    ) -> String? {
        let normalizedExercise = exercise.lowercased()
        let normalizedIssue = issue.lowercased()
        let normalizedRules = Set(failedRules.map { $0.lowercased() })

        if
            normalizedIssue.contains("range of motion")
                || normalizedIssue.contains("depth")
                || normalizedIssue.contains("bottom")
                || normalizedIssue.contains("not low enough")
        {
            return rangeCue(for: normalizedExercise)
        }

        if normalizedRules.contains("alignment") {
            return alignmentCue(for: normalizedExercise)
        }

        if normalizedRules.contains("tempo") {
            return tempoCue(for: normalizedExercise)
        }

        if normalizedRules.contains("stability") {
            return stabilityCue(for: normalizedExercise)
        }

        if normalizedIssue.contains("tempo") || normalizedIssue.contains("fast") || normalizedIssue.contains("rush") {
            return tempoCue(for: normalizedExercise)
        }

        if normalizedIssue.contains("balance") || normalizedIssue.contains("stable") || normalizedIssue.contains("swing") {
            return stabilityCue(for: normalizedExercise)
        }

        guard let primaryMetric else {
            return defaultCue(for: normalizedExercise)
        }

        switch normalizedExercise {
        case _ where normalizedExercise.contains("squat"), _ where normalizedExercise.contains("lunge"):
            return primaryMetric > 100 ? rangeCue(for: normalizedExercise) : defaultCue(for: normalizedExercise)
        case _ where normalizedExercise.contains("push"):
            return primaryMetric > 110 ? rangeCue(for: normalizedExercise) : defaultCue(for: normalizedExercise)
        case _ where normalizedExercise.contains("press"):
            return primaryMetric < 150 ? rangeCue(for: normalizedExercise) : defaultCue(for: normalizedExercise)
        case _ where normalizedExercise.contains("curl"):
            return primaryMetric > 80 ? rangeCue(for: normalizedExercise) : defaultCue(for: normalizedExercise)
        default:
            return defaultCue(for: normalizedExercise)
        }
    }

    private func rangeCue(for exercise: String) -> String {
        switch exercise {
        case _ where exercise.contains("squat"), _ where exercise.contains("lunge"):
            return "Lower hips and bend your knees"
        case _ where exercise.contains("push"):
            return "Lower chest closer to the floor"
        case _ where exercise.contains("press"):
            return "Press arms fully overhead"
        case _ where exercise.contains("curl"):
            return "Curl hands higher toward shoulders"
        default:
            return "Move through the full exercise"
        }
    }

    private func alignmentCue(for exercise: String) -> String {
        switch exercise {
        case _ where exercise.contains("squat"), _ where exercise.contains("lunge"):
            return "Push knees outward and lift chest"
        case _ where exercise.contains("push"):
            return "Brace core and keep hips level"
        case _ where exercise.contains("press"):
            return "Stack wrists over shoulders and brace core"
        case _ where exercise.contains("curl"):
            return "Tuck elbows in and stop swinging"
        default:
            return "Brace core and straighten your posture"
        }
    }

    private func tempoCue(for exercise: String) -> String {
        switch exercise {
        case _ where exercise.contains("squat"), _ where exercise.contains("lunge"):
            return "Slow down and control your knees"
        case _ where exercise.contains("push"):
            return "Lower chest slower and press smoothly"
        case _ where exercise.contains("press"):
            return "Press slower and control your elbows"
        case _ where exercise.contains("curl"):
            return "Curl slower and keep elbows still"
        default:
            return "Slow down and control the rep"
        }
    }

    private func stabilityCue(for exercise: String) -> String {
        switch exercise {
        case _ where exercise.contains("squat"), _ where exercise.contains("lunge"):
            return "Plant feet and brace your core"
        case _ where exercise.contains("push"):
            return "Brace core and stop your hips"
        case _ where exercise.contains("press"):
            return "Set feet and brace your core"
        case _ where exercise.contains("curl"):
            return "Lock elbows in and stop swinging"
        default:
            return "Set your stance and brace core"
        }
    }

    private func defaultCue(for exercise: String) -> String {
        switch exercise {
        case _ where exercise.contains("squat"), _ where exercise.contains("lunge"):
            return "Lift chest and push knees outward"
        case _ where exercise.contains("push"):
            return "Brace core and keep hips level"
        case _ where exercise.contains("press"):
            return "Stack wrists over shoulders and brace core"
        case _ where exercise.contains("curl"):
            return "Tuck elbows in and stop swinging"
        default:
            return "Brace core and reset your posture"
        }
    }
}

private struct CueResult {
    let cue: String
    let provider: FormCoachService.ProviderState
    let status: String
}
