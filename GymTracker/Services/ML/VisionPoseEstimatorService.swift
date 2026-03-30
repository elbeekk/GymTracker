import CoreGraphics
import Foundation
import Vision

final class VisionPoseEstimatorService: PoseEstimating {
    let isOperational = true
    let setupMessage: String? = nil

    private let request = VNDetectHumanBodyPoseRequest()

    func estimatePoses(in pixelBuffer: CVPixelBuffer) throws -> [PosePerson] {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.compactMap { observation in
            makePerson(from: observation)
        }
    }

    private func makePerson(from observation: VNHumanBodyPoseObservation) -> PosePerson? {
        let classifierFrame = ActionClassifierPoseEncoding.makeFrame(from: observation)

        let keypoints = PoseKeypointName.allCases.compactMap { keypointName -> PoseKeypoint? in
            guard
                let jointName = visionJointName(for: keypointName),
                let recognizedPoint = try? observation.recognizedPoint(jointName)
            else {
                return nil
            }

            return PoseKeypoint(
                name: keypointName,
                location: CGPoint(
                    x: recognizedPoint.location.x.clamped(to: 0 ... 1),
                    y: (1 - recognizedPoint.location.y).clamped(to: 0 ... 1)
                ),
                confidence: Double(recognizedPoint.confidence)
            )
        }

        guard !keypoints.isEmpty else {
            return nil
        }

        let score = keypoints.map(\.confidence).reduce(0, +) / Double(keypoints.count)
        guard score > 0.05 else {
            return nil
        }

        return PosePerson(keypoints: keypoints, score: score, classifierFrame: classifierFrame)
    }

    private func visionJointName(for keypointName: PoseKeypointName) -> VNHumanBodyPoseObservation.JointName? {
        switch keypointName {
        case .nose:
            .nose
        case .leftEye:
            .leftEye
        case .rightEye:
            .rightEye
        case .leftEar:
            .leftEar
        case .rightEar:
            .rightEar
        case .leftShoulder:
            .leftShoulder
        case .rightShoulder:
            .rightShoulder
        case .leftElbow:
            .leftElbow
        case .rightElbow:
            .rightElbow
        case .leftWrist:
            .leftWrist
        case .rightWrist:
            .rightWrist
        case .leftHip:
            .leftHip
        case .rightHip:
            .rightHip
        case .leftKnee:
            .leftKnee
        case .rightKnee:
            .rightKnee
        case .leftAnkle:
            .leftAnkle
        case .rightAnkle:
            .rightAnkle
        }
    }
}
