import CoreML
import Foundation

final class CoreMLExerciseClassifierService: ExerciseClassifying {
    let isOperational = true
    let setupMessage: String? = nil

    private let model: ExerciseClassifier
    private let sequenceBuffer = PoseSequenceBuffer(windowSize: 60)

    init(modelName: String) throws {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [
                NSLocalizedDescriptionKey: "Add \(modelName).mlmodel to the app target so the classifier is bundled."
            ])
        }

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        self.model = try ExerciseClassifier(contentsOf: modelURL, configuration: configuration)
    }

    func classify(pose: PosePerson) throws -> ExerciseClassification {
        sequenceBuffer.append(pose.classifierFrame ?? PoseSequenceBuffer.zeroFrame)

        guard sequenceBuffer.isReady else {
            return .unknown
        }

        let input = try ExerciseClassifierInput(poses: sequenceBuffer.makeMultiArray())
        let output = try model.prediction(input: input)
        let label = output.label
        let confidence = output.labelProbabilities[label] ?? 0

        return ExerciseClassification(
            exercise: ExerciseType(rawLabel: label),
            confidence: confidence,
            rawLabel: label
        )
    }

    func reset() {
        sequenceBuffer.reset()
    }
}

private final class PoseSequenceBuffer {
    private let windowSize: Int
    private var frames: [[Float]] = []

    static let zeroFrame = Array(repeating: Float(0), count: 3 * ActionClassifierPoseEncoding.keypointCount)

    init(windowSize: Int) {
        self.windowSize = windowSize
    }

    var isReady: Bool {
        frames.count >= windowSize
    }

    func append(_ frame: [Float]) {
        frames.append(frame)
        if frames.count > windowSize {
            frames.removeFirst(frames.count - windowSize)
        }
    }

    func reset() {
        frames.removeAll()
    }

    func makeMultiArray() throws -> MLMultiArray {
        let multiArray = try MLMultiArray(
            shape: [NSNumber(value: windowSize), 3, NSNumber(value: ActionClassifierPoseEncoding.keypointCount)],
            dataType: .float32
        )

        for frameIndex in 0 ..< min(frames.count, windowSize) {
            let frame = frames[frameIndex]
            for keypointIndex in 0 ..< ActionClassifierPoseEncoding.keypointCount {
                let sourceOffset = keypointIndex * 3
                multiArray[[frameIndex as NSNumber, 0, keypointIndex as NSNumber]] = NSNumber(value: frame[sourceOffset])
                multiArray[[frameIndex as NSNumber, 1, keypointIndex as NSNumber]] = NSNumber(value: frame[sourceOffset + 1])
                multiArray[[frameIndex as NSNumber, 2, keypointIndex as NSNumber]] = NSNumber(value: frame[sourceOffset + 2])
            }
        }

        return multiArray
    }
}
