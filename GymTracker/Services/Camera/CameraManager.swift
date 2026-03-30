import AVFoundation
import CoreMedia
import CoreVideo
import Foundation

final class CameraManager: NSObject {
    enum CameraError: LocalizedError {
        case noRequestedCamera(position: AVCaptureDevice.Position)
        case cannotAddInput
        case cannotAddOutput

        var errorDescription: String? {
            switch self {
            case let .noRequestedCamera(position):
                position == .front
                    ? "Front camera is unavailable on this device."
                    : "Rear camera is unavailable on this device."
            case .cannotAddInput:
                "The camera input could not be added to the capture session."
            case .cannotAddOutput:
                "The video output could not be added to the capture session."
            }
        }
    }

    let session = AVCaptureSession()
    let isPreviewMirrored: Bool
    var onFrame: ((CVPixelBuffer, TimeInterval) -> Void)?

    private let sessionQueue = DispatchQueue(label: "gymtracker.camera.session")
    private let videoOutputQueue: DispatchQueue
    private let preferredPosition: AVCaptureDevice.Position
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false

    init(
        videoOutputQueue: DispatchQueue,
        preferredPosition: AVCaptureDevice.Position = .front,
        previewMirrored: Bool = true
    ) {
        self.videoOutputQueue = videoOutputQueue
        self.preferredPosition = preferredPosition
        self.isPreviewMirrored = previewMirrored
        super.init()
    }

    func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func configureIfNeeded() async throws {
        guard !isConfigured else { return }

        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    try self.configureSession()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func startRunning() {
        sessionQueue.async {
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopRunning() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureSession() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1280x720

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: preferredPosition == .front
                ? [.builtInTrueDepthCamera, .builtInWideAngleCamera]
                : [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: preferredPosition
        )

        guard
            let camera = discoverySession.devices.first ??
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition)
        else {
            throw CameraError.noRequestedCamera(position: preferredPosition)
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        try configureFrameRate(for: camera, preferredFPS: 30)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

        guard session.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }

        isConfigured = true
    }

    private func configureFrameRate(for camera: AVCaptureDevice, preferredFPS: Double) throws {
        let roundedFPS = max(Int32(preferredFPS.rounded()), 1)
        let preferredDuration = CMTime(value: 1, timescale: roundedFPS)
        let supportsPreferredFPS = camera.activeFormat.videoSupportedFrameRateRanges.contains { range in
            range.minFrameRate <= preferredFPS && preferredFPS <= range.maxFrameRate
        }

        guard supportsPreferredFPS else { return }

        try camera.lockForConfiguration()
        camera.activeVideoMinFrameDuration = preferredDuration
        camera.activeVideoMaxFrameDuration = preferredDuration
        camera.unlockForConfiguration()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        onFrame?(pixelBuffer, timestamp)
    }
}
