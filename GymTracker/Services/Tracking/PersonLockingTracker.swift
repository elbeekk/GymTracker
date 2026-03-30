import Foundation

struct CalibrationResult {
    let snapshot: CalibrationSnapshot
    let candidatePose: PosePerson?
}

struct TrackingUpdate {
    let status: TrackingStatus
    let trackedPose: PosePerson?
    let message: String
}

final class PersonLockingTracker {
    var hasLock: Bool { lockedPerson != nil }

    private let configuration: AppConfiguration
    private let visibilityValidator: BodyVisibilityValidator

    private(set) var lockedPerson: LockedPerson?
    private var calibrationCandidate: PosePerson?
    private var calibrationStableFrames = 0
    private var canLockCandidate = false

    init(configuration: AppConfiguration, visibilityValidator: BodyVisibilityValidator) {
        self.configuration = configuration
        self.visibilityValidator = visibilityValidator
    }

    func reset() {
        lockedPerson = nil
        calibrationCandidate = nil
        calibrationStableFrames = 0
        canLockCandidate = false
    }

    func evaluateCalibration(poses: [PosePerson]) -> CalibrationResult {
        let eligible = poses
            .filter(visibilityValidator.isCalibrationEligible(_:))
            .map { pose in
                (pose, calibrationScore(for: pose))
            }
            .sorted { $0.1 > $1.1 }

        guard !eligible.isEmpty else {
            calibrationCandidate = nil
            calibrationStableFrames = 0
            canLockCandidate = false

            let fallbackMessage = poses.first.map { visibilityValidator.assess($0).message } ?? "Show your full body and make an X with your arms"
            return CalibrationResult(
                snapshot: CalibrationSnapshot(
                    progress: 0,
                    canLock: false,
                    candidateID: nil,
                    message: fallbackMessage,
                    onlyOneUserWarning: false
                ),
                candidatePose: nil
            )
        }

        let gesturing = eligible.filter { isFocusGesturePresent($0.0) }

        guard let bestGesture = gesturing.first else {
            calibrationCandidate = nil
            calibrationStableFrames = 0
            canLockCandidate = false

            return CalibrationResult(
                snapshot: CalibrationSnapshot(
                    progress: 0,
                    canLock: false,
                    candidateID: nil,
                    message: "Make an X with your arms to select yourself",
                    onlyOneUserWarning: false
                ),
                candidatePose: nil
            )
        }

        let onlyOneUserWarning = gesturing.count > 1 && abs(bestGesture.1 - gesturing[1].1) < 0.08
        let candidate = bestGesture.0

        if let current = calibrationCandidate, isSameCalibrationCandidate(current, candidate) {
            calibrationStableFrames += 1
        } else {
            calibrationCandidate = candidate
            calibrationStableFrames = 1
        }

        canLockCandidate = calibrationStableFrames >= configuration.tracking.focusGestureStableFrames && !onlyOneUserWarning
        let progress = min(Double(calibrationStableFrames) / Double(configuration.tracking.focusGestureStableFrames), 1)
        let message = onlyOneUserWarning
            ? "Only one user should make the X gesture"
            : (canLockCandidate ? "X detected. Locked on to you." : "Hold the X gesture to lock on")

        return CalibrationResult(
            snapshot: CalibrationSnapshot(
                progress: progress,
                canLock: canLockCandidate,
                candidateID: candidate.id,
                message: message,
                onlyOneUserWarning: onlyOneUserWarning
            ),
            candidatePose: candidate
        )
    }

    func lockCurrentCandidate(at timestamp: TimeInterval) -> Bool {
        guard let candidate = calibrationCandidate, canLockCandidate else { return false }

        lockedPerson = LockedPerson(
            id: candidate.id,
            referencePose: candidate,
            lastPose: candidate,
            lastSeenTimestamp: timestamp,
            missingFrameCount: 0
        )
        return true
    }

    func update(with poses: [PosePerson], timestamp: TimeInterval) -> TrackingUpdate {
        guard var lock = lockedPerson else {
            return TrackingUpdate(status: .calibrating, trackedPose: nil, message: "Calibrate to select yourself")
        }

        let rankedCandidates = poses
            .map { pose in
                (pose, trackingScore(for: pose, against: lock))
            }
            .sorted { $0.1 > $1.1 }

        if let best = rankedCandidates.first, best.1 >= configuration.tracking.matchThreshold {
            lock.lastPose = best.0
            lock.lastSeenTimestamp = timestamp
            lock.missingFrameCount = 0
            lockedPerson = lock
            return TrackingUpdate(status: .locked, trackedPose: best.0, message: "Locked on current user")
        }

        lock.missingFrameCount += 1
        lockedPerson = lock

        if lock.missingFrameCount > configuration.tracking.lostFrameTolerance {
            return TrackingUpdate(status: .lost, trackedPose: nil, message: "Tracking lost — return to position")
        } else {
            return TrackingUpdate(status: .reacquiring, trackedPose: nil, message: "Tracking unstable — hold your position")
        }
    }

    private func calibrationScore(for pose: PosePerson) -> Double {
        let centerPoint = pose.torsoCenter ?? pose.boundingBox.center
        let centerDistance = centerPoint.distance(to: CGPoint(x: 0.5, y: 0.5))
        let normalizedCenterScore = (1 - centerDistance / 0.75).clamped(to: 0 ... 1)
        let sizeScore = min(pose.boundingBox.area / 0.22, 1)
        return normalizedCenterScore * 0.6 + sizeScore * 0.4
    }

    private func isSameCalibrationCandidate(_ lhs: PosePerson, _ rhs: PosePerson) -> Bool {
        let lhsCenter = lhs.torsoCenter ?? lhs.boundingBox.center
        let rhsCenter = rhs.torsoCenter ?? rhs.boundingBox.center
        let centerDistance = lhsCenter.distance(to: rhsCenter)
        let overlap = lhs.boundingBox.intersectionOverUnion(with: rhs.boundingBox)
        return centerDistance < configuration.tracking.candidateSimilarityDistance || overlap > 0.35
    }

    private func trackingScore(for candidate: PosePerson, against lock: LockedPerson) -> Double {
        let lastCenter = lock.lastPose.torsoCenter ?? lock.lastPose.boundingBox.center
        let candidateCenter = candidate.torsoCenter ?? candidate.boundingBox.center
        let jumpDistance = candidateCenter.distance(to: lastCenter)
        let overlap = candidate.boundingBox.intersectionOverUnion(with: lock.lastPose.boundingBox)

        if jumpDistance > configuration.tracking.hardJumpDistance && overlap < 0.08 {
            return 0
        }

        let continuityScore = (1 - jumpDistance / 0.45).clamped(to: 0 ... 1)
        let overlapScore = overlap
        let poseSimilarity = poseSimilarityScore(candidate, lock.lastPose)
        let referenceSimilarity = poseSimilarityScore(candidate, lock.referencePose)

        let areaRatio = candidate.boundingBox.area / max(lock.lastPose.boundingBox.area, 0.001)
        let scaleScore = (1 - abs(areaRatio - 1)).clamped(to: 0 ... 1)

        return overlapScore * 0.35 +
            continuityScore * 0.30 +
            poseSimilarity * 0.20 +
            referenceSimilarity * 0.10 +
            scaleScore * 0.05
    }

    private func poseSimilarityScore(_ lhs: PosePerson, _ rhs: PosePerson) -> Double {
        let anchorPoints: [PoseKeypointName] = [
            .leftShoulder, .rightShoulder,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee
        ]

        let distances = anchorPoints.compactMap { keypointName -> Double? in
            guard
                let lhsPoint = lhs.point(keypointName, minimumConfidence: configuration.pose.essentialKeypointConfidence),
                let rhsPoint = rhs.point(keypointName, minimumConfidence: configuration.pose.essentialKeypointConfidence)
            else {
                return nil
            }
            return lhsPoint.distance(to: rhsPoint)
        }

        guard !distances.isEmpty else { return 0 }
        let averageDistance = distances.reduce(0, +) / Double(distances.count)
        return (1 - averageDistance / 0.25).clamped(to: 0 ... 1)
    }

    private func isFocusGesturePresent(_ pose: PosePerson) -> Bool {
        guard
            let leftShoulder = pose.point(.leftShoulder, minimumConfidence: configuration.pose.essentialKeypointConfidence),
            let rightShoulder = pose.point(.rightShoulder, minimumConfidence: configuration.pose.essentialKeypointConfidence),
            let leftElbow = pose.point(.leftElbow, minimumConfidence: configuration.pose.essentialKeypointConfidence * 0.8),
            let rightElbow = pose.point(.rightElbow, minimumConfidence: configuration.pose.essentialKeypointConfidence * 0.8),
            let leftWrist = pose.point(.leftWrist, minimumConfidence: configuration.pose.essentialKeypointConfidence * 0.7),
            let rightWrist = pose.point(.rightWrist, minimumConfidence: configuration.pose.essentialKeypointConfidence * 0.7),
            let torsoCenter = pose.torsoCenter
        else {
            return false
        }

        let wristsNearCenter = leftWrist.distance(to: torsoCenter) < 0.22 && rightWrist.distance(to: torsoCenter) < 0.22
        let wristsCloseTogether = leftWrist.distance(to: rightWrist) < 0.16
        let elbowsOutsideWrists = leftElbow.distance(to: rightElbow) > leftWrist.distance(to: rightWrist) + 0.08
        let insideTorsoBand = max(leftWrist.y, rightWrist.y) < max(leftShoulder.y, rightShoulder.y) + 0.22
        let armsCrossed = segmentsIntersect(a1: leftElbow, a2: leftWrist, b1: rightElbow, b2: rightWrist) ||
            segmentsIntersect(a1: leftShoulder, a2: leftWrist, b1: rightShoulder, b2: rightWrist)

        return wristsNearCenter && wristsCloseTogether && elbowsOutsideWrists && insideTorsoBand && armsCrossed
    }

    private func segmentsIntersect(a1: CGPoint, a2: CGPoint, b1: CGPoint, b2: CGPoint) -> Bool {
        let o1 = orientation(a1, a2, b1)
        let o2 = orientation(a1, a2, b2)
        let o3 = orientation(b1, b2, a1)
        let o4 = orientation(b1, b2, a2)

        return o1 * o2 < 0 && o3 * o4 < 0
    }

    private func orientation(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> Double {
        Double(q.y - p.y) * Double(r.x - q.x) - Double(q.x - p.x) * Double(r.y - q.y)
    }
}
