import CoreGraphics
import Foundation

enum PoseKeypointName: Int, CaseIterable, Sendable {
    case nose = 0
    case leftEye
    case rightEye
    case leftEar
    case rightEar
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist
    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle
}

struct PoseKeypoint: Identifiable, Sendable {
    let name: PoseKeypointName
    let location: CGPoint
    let confidence: Double

    var id: Int { name.rawValue }
}

struct PosePerson: Identifiable, Sendable {
    static let skeletonConnections: [(PoseKeypointName, PoseKeypointName)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]

    let id: UUID
    let keypoints: [PoseKeypointName: PoseKeypoint]
    let boundingBox: CGRect
    let score: Double
    let classifierFrame: [Float]?

    init(
        id: UUID = UUID(),
        keypoints: [PoseKeypoint],
        boundingBox: CGRect? = nil,
        score: Double,
        classifierFrame: [Float]? = nil
    ) {
        self.id = id
        self.keypoints = Dictionary(uniqueKeysWithValues: keypoints.map { ($0.name, $0) })
        self.boundingBox = boundingBox ?? PosePerson.estimatedBoundingBox(from: keypoints)
        self.score = score
        self.classifierFrame = classifierFrame
    }

    var allKeypoints: [PoseKeypoint] {
        PoseKeypointName.allCases.compactMap { keypoints[$0] }
    }

    var overallConfidence: Double {
        guard !allKeypoints.isEmpty else { return 0 }
        return allKeypoints.map(\.confidence).reduce(0, +) / Double(allKeypoints.count)
    }

    var torsoCenter: CGPoint? {
        let shoulders = midpoint(.leftShoulder, .rightShoulder)
        let hips = midpoint(.leftHip, .rightHip)

        switch (shoulders, hips) {
        case let (shoulders?, hips?):
            return CGPoint(x: (shoulders.x + hips.x) * 0.5, y: (shoulders.y + hips.y) * 0.5)
        case let (shoulders?, nil):
            return shoulders
        case let (nil, hips?):
            return hips
        case (nil, nil):
            return nil
        }
    }

    func keypoint(_ name: PoseKeypointName) -> PoseKeypoint? {
        keypoints[name]
    }

    func point(_ name: PoseKeypointName, minimumConfidence: Double = 0) -> CGPoint? {
        guard let keypoint = keypoints[name], keypoint.confidence >= minimumConfidence else {
            return nil
        }
        return keypoint.location
    }

    func midpoint(_ first: PoseKeypointName, _ second: PoseKeypointName, minimumConfidence: Double = 0.3) -> CGPoint? {
        guard
            let firstPoint = point(first, minimumConfidence: minimumConfidence),
            let secondPoint = point(second, minimumConfidence: minimumConfidence)
        else {
            return nil
        }

        return CGPoint(x: (firstPoint.x + secondPoint.x) * 0.5, y: (firstPoint.y + secondPoint.y) * 0.5)
    }

    private static func estimatedBoundingBox(from keypoints: [PoseKeypoint]) -> CGRect {
        let visible = keypoints.filter { $0.confidence > 0.15 }
        guard !visible.isEmpty else { return .zero }

        let xValues = visible.map(\.location.x)
        let yValues = visible.map(\.location.y)
        let rect = CGRect(
            x: xValues.min() ?? 0,
            y: yValues.min() ?? 0,
            width: (xValues.max() ?? 0) - (xValues.min() ?? 0),
            height: (yValues.max() ?? 0) - (yValues.min() ?? 0)
        )
        return rect.clampedToUnit()
    }
}
