import CoreGraphics
import Foundation

struct BodyVisibilityValidator {
    private let configuration: AppConfiguration
    private let headKeypoints: [PoseKeypointName] = [.nose, .leftEye, .rightEye, .leftEar, .rightEar]
    private let shoulderKeypoints: [PoseKeypointName] = [.leftShoulder, .rightShoulder]
    private let hipKeypoints: [PoseKeypointName] = [.leftHip, .rightHip]
    private let kneeKeypoints: [PoseKeypointName] = [.leftKnee, .rightKnee]
    private let ankleKeypoints: [PoseKeypointName] = [.leftAnkle, .rightAnkle]

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    func assess(_ pose: PosePerson) -> VisibilityAssessment {
        let threshold = configuration.pose.essentialKeypointConfidence
        let coverage = clusterCoverage(for: pose, minimumConfidence: threshold)
        let score = coverage.weightedScore
        let boundingBox = pose.boundingBox.clampedToUnit()
        let verticalClipping = boundingBox.minY <= configuration.pose.edgeMargin ||
            boundingBox.maxY >= (1 - configuration.pose.edgeMargin)
        let horizontalProfile = boundingBox.width > max(boundingBox.height * 1.15, 0.18)

        if pose.overallConfidence < configuration.pose.minimumPoseConfidence * 0.5 || coverage.visiblePointCount == 0 {
            return VisibilityAssessment(
                status: .notVisible,
                message: "Stand fully inside the frame",
                score: score,
                isGoodEnough: false
            )
        }

        if boundingBox.height > configuration.pose.maximumBodyHeightFraction || verticalClipping {
            return VisibilityAssessment(
                status: .tooClose,
                message: "Move camera farther back",
                score: score,
                isGoodEnough: false
            )
        }

        if !coverage.isGoodEnough(horizontalProfile: horizontalProfile) {
            return VisibilityAssessment(
                status: .partial,
                message: coverage.guidanceMessage(horizontalProfile: horizontalProfile),
                score: score,
                isGoodEnough: false
            )
        }

        if pose.overallConfidence < configuration.pose.minimumPoseConfidence {
            return VisibilityAssessment(
                status: .lowConfidence,
                message: "Hold still so tracking can recover",
                score: score,
                isGoodEnough: false
            )
        }

        return VisibilityAssessment(
            status: .fullBody,
            message: "Full body visible",
            score: score,
            isGoodEnough: true
        )
    }

    func isCalibrationEligible(_ pose: PosePerson) -> Bool {
        let coverage = clusterCoverage(for: pose, minimumConfidence: configuration.pose.essentialKeypointConfidence)
        let boundingBox = pose.boundingBox.clampedToUnit()
        let headVisible = coverage.headVisibleCount >= 1
        let shouldersVisible = coverage.shoulderVisibleCount == 2
        let hipsVisible = coverage.hipVisibleCount == 2
        let kneesVisible = coverage.kneeVisibleCount == 2
        let anklesVisible = coverage.ankleVisibleCount == 2
        let heightOkay = boundingBox.height >= configuration.pose.minimumBodyHeightFraction
        let verticallyInside = boundingBox.minY > configuration.pose.edgeMargin &&
            boundingBox.maxY < (1 - configuration.pose.edgeMargin)

        return headVisible &&
            shouldersVisible &&
            hipsVisible &&
            kneesVisible &&
            anklesVisible &&
            heightOkay &&
            verticallyInside &&
            pose.boundingBox.area >= configuration.pose.minimumBoundingBoxArea
    }

    private func isInsideFrame(_ point: CGPoint) -> Bool {
        let margin = configuration.pose.edgeMargin
        return point.x >= margin &&
            point.x <= (1 - margin) &&
            point.y >= margin &&
            point.y <= (1 - margin)
    }

    private func clusterCoverage(for pose: PosePerson, minimumConfidence: Double) -> ClusterCoverage {
        let headVisibleCount = visibleCount(of: headKeypoints, in: pose, minimumConfidence: minimumConfidence)
        let shoulderVisibleCount = visibleCount(of: shoulderKeypoints, in: pose, minimumConfidence: minimumConfidence)
        let hipVisibleCount = visibleCount(of: hipKeypoints, in: pose, minimumConfidence: minimumConfidence)
        let kneeVisibleCount = visibleCount(of: kneeKeypoints, in: pose, minimumConfidence: minimumConfidence)
        let ankleVisibleCount = visibleCount(of: ankleKeypoints, in: pose, minimumConfidence: minimumConfidence)

        return ClusterCoverage(
            headVisibleCount: headVisibleCount,
            shoulderVisibleCount: shoulderVisibleCount,
            hipVisibleCount: hipVisibleCount,
            kneeVisibleCount: kneeVisibleCount,
            ankleVisibleCount: ankleVisibleCount
        )
    }

    private func visibleCount(
        of keypoints: [PoseKeypointName],
        in pose: PosePerson,
        minimumConfidence: Double
    ) -> Int {
        keypoints.filter { keypointName in
            guard let keypoint = pose.keypoint(keypointName) else { return false }
            return keypoint.confidence >= minimumConfidence && isInsideFrame(keypoint.location)
        }.count
    }
}

private struct ClusterCoverage {
    let headVisibleCount: Int
    let shoulderVisibleCount: Int
    let hipVisibleCount: Int
    let kneeVisibleCount: Int
    let ankleVisibleCount: Int

    var visiblePointCount: Int {
        headVisibleCount + shoulderVisibleCount + hipVisibleCount + kneeVisibleCount + ankleVisibleCount
    }

    var weightedScore: Double {
        headCoverage * 0.15 +
            shoulderCoverage * 0.25 +
            hipCoverage * 0.25 +
            kneeCoverage * 0.20 +
            ankleCoverage * 0.15
    }

    var headCoverage: Double { min(Double(headVisibleCount) / 2.0, 1) }
    var shoulderCoverage: Double { Double(shoulderVisibleCount) / 2.0 }
    var hipCoverage: Double { Double(hipVisibleCount) / 2.0 }
    var kneeCoverage: Double { Double(kneeVisibleCount) / 2.0 }
    var ankleCoverage: Double { Double(ankleVisibleCount) / 2.0 }

    var torsoStrongEnough: Bool {
        shoulderVisibleCount >= 1 && hipVisibleCount >= 1
    }

    var lowerBodyStrongEnough: Bool {
        (kneeVisibleCount + ankleVisibleCount) >= 2 && kneeVisibleCount >= 1 && ankleVisibleCount >= 1
    }

    func isGoodEnough(horizontalProfile: Bool) -> Bool {
        let minimumScore = horizontalProfile ? 0.62 : 0.72
        let headOptional = horizontalProfile && shoulderVisibleCount >= 1 && hipVisibleCount >= 1 && (kneeVisibleCount + ankleVisibleCount) >= 3

        return weightedScore >= minimumScore &&
            torsoStrongEnough &&
            lowerBodyStrongEnough &&
            (headVisibleCount >= 1 || headOptional)
    }

    func guidanceMessage(horizontalProfile: Bool) -> String {
        if !torsoStrongEnough {
            return "Keep shoulders and hips visible"
        }

        if !lowerBodyStrongEnough {
            return "Keep knees and ankles in frame"
        }

        if headVisibleCount == 0 && !horizontalProfile {
            return "Keep your head inside the frame"
        }

        return "Full body not visible. Adjust camera placement."
    }
}
