import Foundation

struct ExerciseFrameAnalysis: Sendable {
    let exercise: ExerciseType
    let primaryMetric: Double?
    let metricVelocity: Double
    let movingTowardBottom: Bool
    let movingTowardTop: Bool
    let startPositionValid: Bool
    let bottomPositionValid: Bool
    let bodyAlignmentValid: Bool
    let tempoValid: Bool
    let stabilityValid: Bool
    let formPassed: Bool
    let cue: String?
    let failedRules: [String]
    let poseConfidence: Double
    let isSupported: Bool

    static func unsupported(exercise: ExerciseType, cue: String) -> ExerciseFrameAnalysis {
        ExerciseFrameAnalysis(
            exercise: exercise,
            primaryMetric: nil,
            metricVelocity: 0,
            movingTowardBottom: false,
            movingTowardTop: false,
            startPositionValid: false,
            bottomPositionValid: false,
            bodyAlignmentValid: false,
            tempoValid: false,
            stabilityValid: false,
            formPassed: false,
            cue: cue,
            failedRules: ["Unsupported exercise"],
            poseConfidence: 0,
            isSupported: false
        )
    }
}

struct PoseHistoryEntry {
    let pose: PosePerson
    let timestamp: TimeInterval
    let smoothedMetric: Double?
}

final class PoseHistoryBuffer {
    private let capacity: Int
    private(set) var entries: [PoseHistoryEntry] = []

    init(capacity: Int = 45) {
        self.capacity = capacity
    }

    var lastEntry: PoseHistoryEntry? {
        entries.last
    }

    func append(pose: PosePerson, timestamp: TimeInterval, smoothedMetric: Double?) {
        entries.append(PoseHistoryEntry(pose: pose, timestamp: timestamp, smoothedMetric: smoothedMetric))
        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
    }

    func reset() {
        entries.removeAll()
    }

    func torsoJitter(window: TimeInterval) -> Double {
        guard let latestTimestamp = entries.last?.timestamp else { return 0 }
        let recentEntries = entries.filter { latestTimestamp - $0.timestamp <= window }
        guard recentEntries.count > 1 else { return 0 }

        let distances = zip(recentEntries, recentEntries.dropFirst()).compactMap { lhs, rhs -> Double? in
            guard
                let lhsCenter = lhs.pose.torsoCenter,
                let rhsCenter = rhs.pose.torsoCenter
            else {
                return nil
            }
            return lhsCenter.distance(to: rhsCenter)
        }

        guard !distances.isEmpty else { return 0 }
        return distances.reduce(0, +) / Double(distances.count)
    }
}

final class FormAnalyzer {
    private let configuration: AppConfiguration
    private let library = ExerciseRuleLibrary()
    private let history = PoseHistoryBuffer()

    private var lastSmoothedMetric: Double?
    private var currentExercise: ExerciseType = .unknown

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    func reset() {
        history.reset()
        lastSmoothedMetric = nil
        currentExercise = .unknown
    }

    func analyze(exercise: ExerciseType, pose: PosePerson, timestamp: TimeInterval) -> ExerciseFrameAnalysis {
        if exercise != currentExercise {
            history.reset()
            lastSmoothedMetric = nil
            currentExercise = exercise
        }

        guard let ruleSet = library.ruleSet(for: exercise) else {
            return .unsupported(exercise: exercise, cue: "No form rules configured for \(exercise.displayName) yet")
        }

        let rawMetric = ruleSet.primaryMetric(for: pose)
        let smoothedMetric = smooth(rawMetric)
        let previousMetric = history.lastEntry?.smoothedMetric ?? smoothedMetric
        let previousTimestamp = history.lastEntry?.timestamp ?? timestamp
        let dt = max(timestamp - previousTimestamp, configuration.pose.minimumFrameInterval)
        let velocity = {
            guard let smoothedMetric, let previousMetric else { return 0.0 }
            return (smoothedMetric - previousMetric) / dt
        }()

        history.append(pose: pose, timestamp: timestamp, smoothedMetric: smoothedMetric)
        return ruleSet.evaluate(
            pose: pose,
            smoothedPrimaryMetric: smoothedMetric,
            metricVelocity: velocity,
            history: history,
            configuration: configuration
        )
    }

    private func smooth(_ value: Double?) -> Double? {
        guard let value else {
            lastSmoothedMetric = nil
            return nil
        }

        let smoothedValue: Double
        if let lastSmoothedMetric {
            smoothedValue = configuration.repCounting.smoothingAlpha * value +
                (1 - configuration.repCounting.smoothingAlpha) * lastSmoothedMetric
        } else {
            smoothedValue = value
        }

        lastSmoothedMetric = smoothedValue
        return smoothedValue
    }
}
