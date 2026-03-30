import CoreGraphics
import CoreVideo
import Foundation

protocol PoseEstimating {
    var isOperational: Bool { get }
    var setupMessage: String? { get }
    func estimatePoses(in pixelBuffer: CVPixelBuffer) throws -> [PosePerson]
}

protocol ExerciseClassifying {
    var isOperational: Bool { get }
    var setupMessage: String? { get }
    func classify(pose: PosePerson) throws -> ExerciseClassification
    func reset()
}

struct UnavailablePoseEstimatorService: PoseEstimating {
    let setupMessage: String?
    let isOperational = false

    func estimatePoses(in pixelBuffer: CVPixelBuffer) throws -> [PosePerson] {
        []
    }
}

struct UnavailableExerciseClassifierService: ExerciseClassifying {
    let setupMessage: String?
    let isOperational = false

    func classify(pose: PosePerson) throws -> ExerciseClassification {
        .unknown
    }

    func reset() {}
}
