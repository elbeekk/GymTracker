import Foundation

struct RepGatingContext {
    let trackingLocked: Bool
    let fullBodyVisible: Bool
    let classificationStable: Bool
    let classificationConfidenceGood: Bool
    let poseConfidenceGood: Bool

    var isReady: Bool {
        trackingLocked && fullBodyVisible && classificationStable && classificationConfidenceGood && poseConfidenceGood
    }
}

final class RepCounter {
    private let configuration: AppConfiguration

    private var repCount = 0
    private var phase: RepPhase = .idle
    private var invalidAttemptStreak = 0

    private var cycleStartedAt: TimeInterval?
    private var bottomReachedAt: TimeInterval?
    private var cycleFormFailed = false
    private var cycleFailureCue: String?
    private var reachedBottom = false

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    func resetForNewExercise() {
        repCount = 0
        invalidAttemptStreak = 0
        clearCycle(phase: .idle)
    }

    func pause() {
        clearCycle(phase: .idle)
    }

    func process(
        analysis: ExerciseFrameAnalysis?,
        gating: RepGatingContext,
        timestamp: TimeInterval
    ) -> RepCounterSnapshot {
        guard gating.isReady, let analysis, analysis.isSupported else {
            clearCycle(phase: .idle)
            return snapshot()
        }

        switch phase {
        case .idle:
            if analysis.startPositionValid {
                phase = .ready
            }

        case .ready:
            if analysis.movingTowardBottom {
                phase = .descending
                cycleStartedAt = timestamp
                cycleFormFailed = !analysis.formPassed
                cycleFailureCue = analysis.formPassed ? nil : invalidCue(for: analysis)
            } else if !analysis.startPositionValid {
                phase = .idle
            }

        case .descending:
            markCycleFailureIfNeeded(from: analysis)
            if analysis.bottomPositionValid {
                phase = .bottom
                reachedBottom = true
                bottomReachedAt = timestamp
            } else if analysis.movingTowardTop && !reachedBottom {
                return completeInvalidRep(message: rangeOfMotionCue(for: analysis.exercise))
            }

        case .bottom:
            markCycleFailureIfNeeded(from: analysis)
            if
                let bottomReachedAt,
                timestamp - bottomReachedAt >= configuration.repCounting.minimumBottomPause,
                analysis.movingTowardTop
            {
                phase = .ascending
            }

        case .ascending:
            markCycleFailureIfNeeded(from: analysis)
            if analysis.startPositionValid {
                return completeCycle(timestamp: timestamp, analysis: analysis)
            } else if analysis.movingTowardBottom {
                phase = .descending
            }
        }

        return snapshot()
    }

    private func completeCycle(timestamp: TimeInterval, analysis: ExerciseFrameAnalysis) -> RepCounterSnapshot {
        let duration = timestamp - (cycleStartedAt ?? timestamp)
        guard reachedBottom else {
            return completeInvalidRep(message: rangeOfMotionCue(for: analysis.exercise))
        }

        guard duration >= configuration.repCounting.minimumRepDuration else {
            return completeInvalidRep(message: tempoCue(for: analysis.exercise))
        }

        guard !cycleFormFailed, analysis.formPassed else {
            return completeInvalidRep(message: cycleFailureCue ?? defaultCue(for: analysis.exercise))
        }

        repCount += 1
        invalidAttemptStreak = 0
        clearCycle(phase: .ready)
        return snapshot(didCountRep: true, message: "Valid rep counted")
    }

    private func completeInvalidRep(message: String) -> RepCounterSnapshot {
        invalidAttemptStreak += 1
        clearCycle(phase: .ready)
        return snapshot(lastRepWasInvalid: true, message: message)
    }

    private func markCycleFailureIfNeeded(from analysis: ExerciseFrameAnalysis) {
        guard !analysis.formPassed else { return }
        cycleFormFailed = true
        cycleFailureCue = invalidCue(for: analysis)
    }

    private func invalidCue(for analysis: ExerciseFrameAnalysis) -> String {
        if !analysis.bottomPositionValid {
            return rangeOfMotionCue(for: analysis.exercise)
        }

        if let cue = analysis.cue, !cue.isEmpty {
            return cue
        }

        return defaultCue(for: analysis.exercise)
    }

    private func rangeOfMotionCue(for exercise: ExerciseType) -> String {
        switch exercise {
        case .squat, .lunge:
            return "Lower hips and bend your knees more"
        case .pushUp:
            return "Lower chest closer to the floor"
        case .shoulderPress:
            return "Press arms fully overhead"
        case .bicepCurl:
            return "Curl hands higher toward shoulders"
        case .unknown:
            return "Complete the full movement before returning"
        }
    }

    private func tempoCue(for exercise: ExerciseType) -> String {
        switch exercise {
        case .squat, .lunge:
            return "Slow down and control your knees"
        case .pushUp:
            return "Lower slower and press with control"
        case .shoulderPress:
            return "Press slower and control your elbows"
        case .bicepCurl:
            return "Curl slower and lower with control"
        case .unknown:
            return "Slow down and control the full rep"
        }
    }

    private func defaultCue(for exercise: ExerciseType) -> String {
        switch exercise {
        case .squat, .lunge:
            return "Lift chest and push knees outward"
        case .pushUp:
            return "Brace core and keep hips level"
        case .shoulderPress:
            return "Stack wrists over shoulders and brace core"
        case .bicepCurl:
            return "Tuck elbows in and stop swinging"
        case .unknown:
            return "Reset your form before the next rep"
        }
    }

    private func clearCycle(phase: RepPhase) {
        self.phase = phase
        cycleStartedAt = nil
        bottomReachedAt = nil
        cycleFormFailed = false
        cycleFailureCue = nil
        reachedBottom = false
    }

    private func snapshot(
        didCountRep: Bool = false,
        lastRepWasInvalid: Bool = false,
        message: String? = nil
    ) -> RepCounterSnapshot {
        RepCounterSnapshot(
            repCount: repCount,
            phase: phase,
            invalidAttemptStreak: invalidAttemptStreak,
            didCountRep: didCountRep,
            lastRepWasInvalid: lastRepWasInvalid,
            eventMessage: message
        )
    }
}
