import Foundation

protocol ExerciseRuleSet {
    var exercise: ExerciseType { get }
    var metricDropsTowardBottom: Bool { get }

    func primaryMetric(for pose: PosePerson) -> Double?
    func evaluate(
        pose: PosePerson,
        smoothedPrimaryMetric: Double?,
        metricVelocity: Double,
        history: PoseHistoryBuffer,
        configuration: AppConfiguration
    ) -> ExerciseFrameAnalysis
}

extension ExerciseRuleSet {
    func movementFlags(metricVelocity: Double, configuration: AppConfiguration) -> (towardBottom: Bool, towardTop: Bool) {
        let threshold = configuration.repCounting.movementVelocityThreshold
        if metricDropsTowardBottom {
            return (metricVelocity < -threshold, metricVelocity > threshold)
        } else {
            return (metricVelocity > threshold, metricVelocity < -threshold)
        }
    }
}

struct ExerciseRuleLibrary {
    func ruleSet(for exercise: ExerciseType) -> (any ExerciseRuleSet)? {
        switch exercise {
        case .squat:
            SquatRuleSet()
        case .pushUp:
            PushUpRuleSet()
        case .shoulderPress:
            ShoulderPressRuleSet()
        case .bicepCurl:
            BicepCurlRuleSet()
        default:
            nil
        }
    }
}

struct SquatRuleSet: ExerciseRuleSet {
    let exercise: ExerciseType = .squat
    let metricDropsTowardBottom = true

    func primaryMetric(for pose: PosePerson) -> Double? {
        let left = kneeAngle(on: .leftHip, .leftKnee, .leftAnkle, pose: pose)
        let right = kneeAngle(on: .rightHip, .rightKnee, .rightAnkle, pose: pose)
        return AngleCalculator.average([left, right])
    }

    func evaluate(
        pose: PosePerson,
        smoothedPrimaryMetric: Double?,
        metricVelocity: Double,
        history: PoseHistoryBuffer,
        configuration: AppConfiguration
    ) -> ExerciseFrameAnalysis {
        let movement = movementFlags(metricVelocity: metricVelocity, configuration: configuration)
        let leftKnee = kneeAngle(on: .leftHip, .leftKnee, .leftAnkle, pose: pose)
        let rightKnee = kneeAngle(on: .rightHip, .rightKnee, .rightAnkle, pose: pose)
        let kneeAngle = AngleCalculator.average([leftKnee, rightKnee])
        let leftHip = hipAngle(on: .leftShoulder, .leftHip, .leftKnee, pose: pose)
        let rightHip = hipAngle(on: .rightShoulder, .rightHip, .rightKnee, pose: pose)
        let hipAngle = AngleCalculator.average([leftHip, rightHip])

        guard
            let shoulderCenter = pose.midpoint(.leftShoulder, .rightShoulder, minimumConfidence: 0.3),
            let hipCenter = pose.midpoint(.leftHip, .rightHip, minimumConfidence: 0.3),
            let kneeAngle,
            let hipAngle
        else {
            return .unsupported(exercise: exercise, cue: "Hold a clearer full-body squat pose")
        }

        let torsoLean = AngleCalculator.leanFromVertical(upper: shoulderCenter, lower: hipCenter)
        let jitter = history.torsoJitter(window: 0.6)
        let leftRightSymmetry = abs((leftKnee ?? kneeAngle) - (rightKnee ?? kneeAngle))

        let startPositionValid = kneeAngle > 155 && torsoLean < 30
        let bottomPositionValid = kneeAngle < 95 && hipAngle < 128
        let bodyAlignmentValid = torsoLean < 38 && leftRightSymmetry < 18
        let tempoValid = abs(metricVelocity) < 240
        let stabilityValid = jitter < 0.035
        let formPassed = bodyAlignmentValid && tempoValid && stabilityValid

        let failedRules = failedRules(
            bodyAlignmentValid: bodyAlignmentValid,
            tempoValid: tempoValid,
            stabilityValid: stabilityValid
        )

        let cue: String? = {
            if !bodyAlignmentValid {
                return "Lift chest and push knees outward"
            }
            if !tempoValid {
                return "Slow down and control your knees"
            }
            if !stabilityValid {
                return "Plant feet and brace your core"
            }
            if movement.towardTop && !bottomPositionValid {
                return "Lower hips and bend your knees more"
            }
            return "Drive through heels and stand tall"
        }()

        return ExerciseFrameAnalysis(
            exercise: exercise,
            primaryMetric: smoothedPrimaryMetric,
            metricVelocity: metricVelocity,
            movingTowardBottom: movement.towardBottom,
            movingTowardTop: movement.towardTop,
            startPositionValid: startPositionValid,
            bottomPositionValid: bottomPositionValid,
            bodyAlignmentValid: bodyAlignmentValid,
            tempoValid: tempoValid,
            stabilityValid: stabilityValid,
            formPassed: formPassed,
            cue: cue,
            failedRules: failedRules,
            poseConfidence: pose.overallConfidence,
            isSupported: true
        )
    }

    private func kneeAngle(on hip: PoseKeypointName, _ knee: PoseKeypointName, _ ankle: PoseKeypointName, pose: PosePerson) -> Double? {
        guard
            let hipPoint = pose.point(hip, minimumConfidence: 0.3),
            let kneePoint = pose.point(knee, minimumConfidence: 0.3),
            let anklePoint = pose.point(ankle, minimumConfidence: 0.3)
        else {
            return nil
        }
        return AngleCalculator.angle(hipPoint, kneePoint, anklePoint)
    }

    private func hipAngle(on shoulder: PoseKeypointName, _ hip: PoseKeypointName, _ knee: PoseKeypointName, pose: PosePerson) -> Double? {
        guard
            let shoulderPoint = pose.point(shoulder, minimumConfidence: 0.3),
            let hipPoint = pose.point(hip, minimumConfidence: 0.3),
            let kneePoint = pose.point(knee, minimumConfidence: 0.3)
        else {
            return nil
        }
        return AngleCalculator.angle(shoulderPoint, hipPoint, kneePoint)
    }

    private func failedRules(bodyAlignmentValid: Bool, tempoValid: Bool, stabilityValid: Bool) -> [String] {
        var rules: [String] = []
        if !bodyAlignmentValid { rules.append("Alignment") }
        if !tempoValid { rules.append("Tempo") }
        if !stabilityValid { rules.append("Stability") }
        return rules
    }
}

struct PushUpRuleSet: ExerciseRuleSet {
    let exercise: ExerciseType = .pushUp
    let metricDropsTowardBottom = true

    func primaryMetric(for pose: PosePerson) -> Double? {
        let left = elbowAngle(on: .leftShoulder, .leftElbow, .leftWrist, pose: pose)
        let right = elbowAngle(on: .rightShoulder, .rightElbow, .rightWrist, pose: pose)
        return AngleCalculator.average([left, right])
    }

    func evaluate(
        pose: PosePerson,
        smoothedPrimaryMetric: Double?,
        metricVelocity: Double,
        history: PoseHistoryBuffer,
        configuration: AppConfiguration
    ) -> ExerciseFrameAnalysis {
        let movement = movementFlags(metricVelocity: metricVelocity, configuration: configuration)
        let leftElbow = elbowAngle(on: .leftShoulder, .leftElbow, .leftWrist, pose: pose)
        let rightElbow = elbowAngle(on: .rightShoulder, .rightElbow, .rightWrist, pose: pose)
        let elbowAngle = AngleCalculator.average([leftElbow, rightElbow])
        let leftLine = bodyLineAngle(shoulder: .leftShoulder, hip: .leftHip, ankle: .leftAnkle, pose: pose)
        let rightLine = bodyLineAngle(shoulder: .rightShoulder, hip: .rightHip, ankle: .rightAnkle, pose: pose)
        let lineAngle = AngleCalculator.average([leftLine, rightLine])

        guard let elbowAngle, let lineAngle else {
            return .unsupported(exercise: exercise, cue: "Show your shoulders, hips, and ankles clearly for push-up tracking")
        }

        let lineDeviation = abs(180 - lineAngle)
        let jitter = history.torsoJitter(window: 0.6)
        let hipLevelDifference: Double = {
            guard
                let leftHip = pose.point(.leftHip, minimumConfidence: 0.3),
                let rightHip = pose.point(.rightHip, minimumConfidence: 0.3)
            else {
                return 0
            }
            return abs(Double(leftHip.y - rightHip.y))
        }()

        let startPositionValid = elbowAngle > 160 && lineDeviation < 16
        let bottomPositionValid = elbowAngle < 95 && lineDeviation < 24
        let bodyAlignmentValid = lineDeviation < 24 && hipLevelDifference < 0.10
        let tempoValid = abs(metricVelocity) < 260
        let stabilityValid = jitter < 0.03
        let formPassed = bodyAlignmentValid && tempoValid && stabilityValid

        let failedRules = failedRules(
            bodyAlignmentValid: bodyAlignmentValid,
            tempoValid: tempoValid,
            stabilityValid: stabilityValid
        )

        let cue: String? = {
            if !bodyAlignmentValid {
                return "Brace core and keep hips level"
            }
            if !tempoValid {
                return "Lower slower and press with control"
            }
            if !stabilityValid {
                return "Tighten core and stop hips swinging"
            }
            if movement.towardTop && !bottomPositionValid {
                return "Lower chest closer to the floor"
            }
            return "Press up strong and stay straight"
        }()

        return ExerciseFrameAnalysis(
            exercise: exercise,
            primaryMetric: smoothedPrimaryMetric,
            metricVelocity: metricVelocity,
            movingTowardBottom: movement.towardBottom,
            movingTowardTop: movement.towardTop,
            startPositionValid: startPositionValid,
            bottomPositionValid: bottomPositionValid,
            bodyAlignmentValid: bodyAlignmentValid,
            tempoValid: tempoValid,
            stabilityValid: stabilityValid,
            formPassed: formPassed,
            cue: cue,
            failedRules: failedRules,
            poseConfidence: pose.overallConfidence,
            isSupported: true
        )
    }

    private func elbowAngle(on shoulder: PoseKeypointName, _ elbow: PoseKeypointName, _ wrist: PoseKeypointName, pose: PosePerson) -> Double? {
        guard
            let shoulderPoint = pose.point(shoulder, minimumConfidence: 0.3),
            let elbowPoint = pose.point(elbow, minimumConfidence: 0.3),
            let wristPoint = pose.point(wrist, minimumConfidence: 0.3)
        else {
            return nil
        }
        return AngleCalculator.angle(shoulderPoint, elbowPoint, wristPoint)
    }

    private func bodyLineAngle(shoulder: PoseKeypointName, hip: PoseKeypointName, ankle: PoseKeypointName, pose: PosePerson) -> Double? {
        guard
            let shoulderPoint = pose.point(shoulder, minimumConfidence: 0.3),
            let hipPoint = pose.point(hip, minimumConfidence: 0.3),
            let anklePoint = pose.point(ankle, minimumConfidence: 0.3)
        else {
            return nil
        }
        return AngleCalculator.angle(shoulderPoint, hipPoint, anklePoint)
    }

    private func failedRules(bodyAlignmentValid: Bool, tempoValid: Bool, stabilityValid: Bool) -> [String] {
        var rules: [String] = []
        if !bodyAlignmentValid { rules.append("Alignment") }
        if !tempoValid { rules.append("Tempo") }
        if !stabilityValid { rules.append("Stability") }
        return rules
    }
}

struct ShoulderPressRuleSet: ExerciseRuleSet {
    let exercise: ExerciseType = .shoulderPress
    let metricDropsTowardBottom = false

    func primaryMetric(for pose: PosePerson) -> Double? {
        let left = elbowAngle(on: .leftShoulder, .leftElbow, .leftWrist, pose: pose)
        let right = elbowAngle(on: .rightShoulder, .rightElbow, .rightWrist, pose: pose)
        return AngleCalculator.average([left, right])
    }

    func evaluate(
        pose: PosePerson,
        smoothedPrimaryMetric: Double?,
        metricVelocity: Double,
        history: PoseHistoryBuffer,
        configuration: AppConfiguration
    ) -> ExerciseFrameAnalysis {
        let movement = movementFlags(metricVelocity: metricVelocity, configuration: configuration)
        let leftElbow = elbowAngle(on: .leftShoulder, .leftElbow, .leftWrist, pose: pose)
        let rightElbow = elbowAngle(on: .rightShoulder, .rightElbow, .rightWrist, pose: pose)
        let elbowAngle = AngleCalculator.average([leftElbow, rightElbow])

        guard
            let elbowAngle,
            let leftShoulder = pose.point(.leftShoulder, minimumConfidence: 0.3),
            let rightShoulder = pose.point(.rightShoulder, minimumConfidence: 0.3),
            let leftWrist = pose.point(.leftWrist, minimumConfidence: 0.3),
            let rightWrist = pose.point(.rightWrist, minimumConfidence: 0.3),
            let shoulderCenter = pose.midpoint(.leftShoulder, .rightShoulder, minimumConfidence: 0.3),
            let hipCenter = pose.midpoint(.leftHip, .rightHip, minimumConfidence: 0.3)
        else {
            return .unsupported(exercise: exercise, cue: "Show both shoulders, elbows, and wrists for shoulder press tracking")
        }

        let torsoLean = AngleCalculator.leanFromVertical(upper: shoulderCenter, lower: hipCenter)
        let wristsNearRackHeight = abs(Double(leftWrist.y - leftShoulder.y)) < 0.18 &&
            abs(Double(rightWrist.y - rightShoulder.y)) < 0.18
        let wristsAboveShoulders = leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y
        let wristStack = abs(Double(leftWrist.x - leftShoulder.x)) < 0.18 &&
            abs(Double(rightWrist.x - rightShoulder.x)) < 0.18
        let leftRightSymmetry = abs((leftElbow ?? elbowAngle) - (rightElbow ?? elbowAngle))
        let jitter = history.torsoJitter(window: 0.6)

        let startPositionValid = elbowAngle > 70 && elbowAngle < 135 && wristsNearRackHeight && torsoLean < 22
        let bottomPositionValid = elbowAngle > 156 && wristsAboveShoulders && wristStack
        let bodyAlignmentValid = torsoLean < 24 && wristStack && leftRightSymmetry < 20
        let tempoValid = abs(metricVelocity) < 280
        let stabilityValid = jitter < 0.035
        let formPassed = bodyAlignmentValid && tempoValid && stabilityValid

        let cue: String? = {
            if !bodyAlignmentValid {
                return "Stack wrists over shoulders and brace core"
            }
            if !tempoValid {
                return "Press slower and control your elbows"
            }
            if !stabilityValid {
                return "Set feet and brace your core"
            }
            if movement.towardTop && !bottomPositionValid {
                return "Press arms fully overhead"
            }
            return "Press tall and lower with control"
        }()

        return ExerciseFrameAnalysis(
            exercise: exercise,
            primaryMetric: smoothedPrimaryMetric,
            metricVelocity: metricVelocity,
            movingTowardBottom: movement.towardBottom,
            movingTowardTop: movement.towardTop,
            startPositionValid: startPositionValid,
            bottomPositionValid: bottomPositionValid,
            bodyAlignmentValid: bodyAlignmentValid,
            tempoValid: tempoValid,
            stabilityValid: stabilityValid,
            formPassed: formPassed,
            cue: cue,
            failedRules: failedRules(bodyAlignmentValid: bodyAlignmentValid, tempoValid: tempoValid, stabilityValid: stabilityValid),
            poseConfidence: pose.overallConfidence,
            isSupported: true
        )
    }

    private func elbowAngle(on shoulder: PoseKeypointName, _ elbow: PoseKeypointName, _ wrist: PoseKeypointName, pose: PosePerson) -> Double? {
        guard
            let shoulderPoint = pose.point(shoulder, minimumConfidence: 0.3),
            let elbowPoint = pose.point(elbow, minimumConfidence: 0.3),
            let wristPoint = pose.point(wrist, minimumConfidence: 0.3)
        else {
            return nil
        }
        return AngleCalculator.angle(shoulderPoint, elbowPoint, wristPoint)
    }

    private func failedRules(bodyAlignmentValid: Bool, tempoValid: Bool, stabilityValid: Bool) -> [String] {
        var rules: [String] = []
        if !bodyAlignmentValid { rules.append("Alignment") }
        if !tempoValid { rules.append("Tempo") }
        if !stabilityValid { rules.append("Stability") }
        return rules
    }
}

struct BicepCurlRuleSet: ExerciseRuleSet {
    let exercise: ExerciseType = .bicepCurl
    let metricDropsTowardBottom = true

    func primaryMetric(for pose: PosePerson) -> Double? {
        let left = elbowAngle(on: .leftShoulder, .leftElbow, .leftWrist, pose: pose)
        let right = elbowAngle(on: .rightShoulder, .rightElbow, .rightWrist, pose: pose)
        return AngleCalculator.average([left, right])
    }

    func evaluate(
        pose: PosePerson,
        smoothedPrimaryMetric: Double?,
        metricVelocity: Double,
        history: PoseHistoryBuffer,
        configuration: AppConfiguration
    ) -> ExerciseFrameAnalysis {
        let movement = movementFlags(metricVelocity: metricVelocity, configuration: configuration)
        let leftElbow = elbowAngle(on: .leftShoulder, .leftElbow, .leftWrist, pose: pose)
        let rightElbow = elbowAngle(on: .rightShoulder, .rightElbow, .rightWrist, pose: pose)
        let elbowAngle = AngleCalculator.average([leftElbow, rightElbow])

        guard
            let elbowAngle,
            let leftElbowPoint = pose.point(.leftElbow, minimumConfidence: 0.3),
            let rightElbowPoint = pose.point(.rightElbow, minimumConfidence: 0.3),
            let leftHip = pose.point(.leftHip, minimumConfidence: 0.3),
            let rightHip = pose.point(.rightHip, minimumConfidence: 0.3),
            let shoulderCenter = pose.midpoint(.leftShoulder, .rightShoulder, minimumConfidence: 0.3),
            let hipCenter = pose.midpoint(.leftHip, .rightHip, minimumConfidence: 0.3)
        else {
            return .unsupported(exercise: exercise, cue: "Show your elbows and torso clearly for curl tracking")
        }

        let torsoLean = AngleCalculator.leanFromVertical(upper: shoulderCenter, lower: hipCenter)
        let leftElbowDrift = leftElbowPoint.distance(to: leftHip)
        let rightElbowDrift = rightElbowPoint.distance(to: rightHip)
        let averageElbowDrift = (leftElbowDrift + rightElbowDrift) * 0.5
        let leftRightSymmetry = abs((leftElbow ?? elbowAngle) - (rightElbow ?? elbowAngle))
        let jitter = history.torsoJitter(window: 0.6)

        let startPositionValid = elbowAngle > 148 && averageElbowDrift < 0.24 && torsoLean < 18
        let bottomPositionValid = elbowAngle < 72
        let bodyAlignmentValid = averageElbowDrift < 0.26 && torsoLean < 20 && leftRightSymmetry < 24
        let tempoValid = abs(metricVelocity) < 260
        let stabilityValid = jitter < 0.03
        let formPassed = bodyAlignmentValid && tempoValid && stabilityValid

        let cue: String? = {
            if !bodyAlignmentValid {
                return "Tuck elbows in and stop swinging"
            }
            if !tempoValid {
                return "Curl slower and lower with control"
            }
            if !stabilityValid {
                return "Stand tall and stop body swinging"
            }
            if movement.towardTop && !bottomPositionValid {
                return "Curl hands higher toward shoulders"
            }
            return "Squeeze curls high and lower slowly"
        }()

        return ExerciseFrameAnalysis(
            exercise: exercise,
            primaryMetric: smoothedPrimaryMetric,
            metricVelocity: metricVelocity,
            movingTowardBottom: movement.towardBottom,
            movingTowardTop: movement.towardTop,
            startPositionValid: startPositionValid,
            bottomPositionValid: bottomPositionValid,
            bodyAlignmentValid: bodyAlignmentValid,
            tempoValid: tempoValid,
            stabilityValid: stabilityValid,
            formPassed: formPassed,
            cue: cue,
            failedRules: failedRules(bodyAlignmentValid: bodyAlignmentValid, tempoValid: tempoValid, stabilityValid: stabilityValid),
            poseConfidence: pose.overallConfidence,
            isSupported: true
        )
    }

    private func elbowAngle(on shoulder: PoseKeypointName, _ elbow: PoseKeypointName, _ wrist: PoseKeypointName, pose: PosePerson) -> Double? {
        guard
            let shoulderPoint = pose.point(shoulder, minimumConfidence: 0.3),
            let elbowPoint = pose.point(elbow, minimumConfidence: 0.3),
            let wristPoint = pose.point(wrist, minimumConfidence: 0.3)
        else {
            return nil
        }
        return AngleCalculator.angle(shoulderPoint, elbowPoint, wristPoint)
    }

    private func failedRules(bodyAlignmentValid: Bool, tempoValid: Bool, stabilityValid: Bool) -> [String] {
        var rules: [String] = []
        if !bodyAlignmentValid { rules.append("Alignment") }
        if !tempoValid { rules.append("Tempo") }
        if !stabilityValid { rules.append("Stability") }
        return rules
    }
}
