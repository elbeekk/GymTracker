import Foundation
import Vision

enum ActionClassifierPoseEncoding {
    static let keypointCount = 18

    static func makeFrame(from observation: VNHumanBodyPoseObservation) -> [Float]? {
        guard let multiArray = try? observation.keypointsMultiArray() else {
            return nil
        }

        return flatten(multiArray)
    }

    static func flatten(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        return (0 ..< count).map { index in
            multiArray[index].floatValue
        }
    }
}
