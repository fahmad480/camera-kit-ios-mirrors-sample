import AVFoundation
import Foundation
import SCSDKCameraKit

public class MirrorAVSessionInput: NSObject, Input {
    public var destination: InputDestination?
    public private(set) var frameSize: CGSize
    public private(set) var frameOrientation: AVCaptureVideoOrientation
    public private(set) var videoOrientation: AVCaptureVideoOrientation
    public private(set) var isVideoMirrored: Bool
    public var position: AVCaptureDevice.Position {
        didSet {
            guard position != oldValue else { return }
            videoSession.beginConfiguration()
            if let videoDeviceInput { videoSession.removeInput(videoDeviceInput) }
            if let device = captureDevice {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if videoSession.canAddInput(input) { videoSession.addInput(input) }
                    update(input: input, isAsync: false)
                    videoSession.commitConfiguration()
                    destination?.inputChangedAttributes(self)
                    
                    // Post notification that input changed
                    NotificationCenter.default.post(name: NSNotification.Name.cameraKitInputDidChange, object: self)
                } catch {
                    debugPrint("[\(String(describing: self))]: Failed to add \(position) input")
                }
            }
        }
    }

    private var captureDevice: AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position)
    }

    public var isRunning: Bool { videoSession.isRunning }
    public var horizontalFieldOfView: CGFloat { fieldOfView }

    private var fieldOfView: CGFloat
    private var format: AVCaptureDevice.Format?
    private var prevCaptureInput: AVCaptureInput?

    private let context = CIContext()
    private let videoSession: AVCaptureSession
    private let videoOutput: AVCaptureVideoDataOutput

    private var videoDeviceInput: AVCaptureDeviceInput? {
        deviceInput(for: .video, session: videoSession)
    }

    private var videoConnection: AVCaptureConnection? {
        videoOutput.connection(with: .video)
    }

    private let videoQueue: DispatchQueue
    private let configurationQueue: DispatchQueue

    public init(session: AVCaptureSession, fieldOfView: CGFloat = Constants.defaultFieldOfView) {
        self.fieldOfView = fieldOfView
        self.videoSession = session
        self.frameOrientation = .portrait
        self.configurationQueue = DispatchQueue(label: "com.snap.mirror.avsessioninput.configuration")
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoQueue = DispatchQueue(label: "com.snap.mirror.videoOutput")
        self.frameSize = UIScreen.main.bounds.size
        self.position = .front
        self.isVideoMirrored = true
        self.videoOrientation = .landscapeLeft
        super.init()

        videoSession.beginConfiguration()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if videoSession.canAddOutput(videoOutput) { videoSession.addOutput(videoOutput) }
        videoConnection?.videoOrientation = videoOrientation
        videoSession.commitConfiguration()
    }

    public func startRunning() {
        restoreFormat()
        videoSession.startRunning()
    }

    public func stopRunning() {
        storeFormat()
        videoSession.stopRunning()
    }

    public func setFrameOrientation(_ orientation: AVCaptureVideoOrientation) {
        self.frameOrientation = orientation
        destination?.inputChangedAttributes(self)
    }

    public func setVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        self.videoOrientation = orientation
        configurationQueue.async { [weak self] in
            self?.videoConnection?.videoOrientation = orientation
        }
        destination?.inputChangedAttributes(self)
    }

    public func toggleVideoMirror() {
        self.isVideoMirrored = !self.isVideoMirrored
        configurationQueue.async { [weak self] in
            self?.videoConnection?.isVideoMirrored = self?.isVideoMirrored ?? true
        }
        destination?.inputChangedAttributes(self)
    }
}

extension MirrorAVSessionInput: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if output == videoOutput {
            if let input = connection.inputPorts.first?.input, input != prevCaptureInput {
                update(input: input)
                destination?.inputChangedAttributes(self)
                
                // Post notification that input changed
                NotificationCenter.default.post(name: NSNotification.Name.cameraKitInputDidChange, object: self)
            }
            destination?.input(self, receivedVideoSampleBuffer: sampleBuffer)
        }
    }
}

private extension MirrorAVSessionInput {
    func restoreFormat() {
        if let format, let device = videoDeviceInput?.device {
            do {
                try device.lockForConfiguration()
                device.activeFormat = format
                device.unlockForConfiguration()
                self.format = nil
            } catch {
                debugPrint("[\(String(describing: self))]: Failed to restore format")
            }
        }
    }

    func storeFormat() {
        format = videoDeviceInput?.device.activeFormat
    }

    func deviceInput(for mediaType: AVMediaType, session: AVCaptureSession) -> AVCaptureDeviceInput? {
        for input in session.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput, deviceInput.device.hasMediaType(mediaType) {
                return deviceInput
            }
        }
        return nil
    }

    func update(input: AVCaptureInput, isAsync: Bool = true) {
        if let input = input as? AVCaptureDeviceInput {
            fieldOfView = CGFloat(input.device.activeFormat.videoFieldOfView)
            position = input.device.position
            format = input.device.activeFormat
            
            // Update frameSize based on the actual format dimensions
            let dimensions = CMVideoFormatDescriptionGetDimensions(input.device.activeFormat.formatDescription)
            frameSize = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
        }

        isVideoMirrored = position == .front

        if isAsync {
            configurationQueue.async { [weak self] in
                self?.updateConnection()
            }
        } else {
            updateConnection()
        }

        prevCaptureInput = input
    }

    func updateConnection() {
        if let isMirrored = videoConnection?.isVideoMirrored, isMirrored != isVideoMirrored {
            videoConnection?.isVideoMirrored = isVideoMirrored
        }

        if let orientation = videoConnection?.videoOrientation, orientation != videoOrientation {
            videoConnection?.videoOrientation = videoOrientation
        }
    }
}

extension MirrorAVSessionInput {
    public enum Constants {
        public static let defaultFieldOfView: CGFloat = 78.0
    }
}

/// CameraKit notification when input changes
extension NSNotification.Name {
    public static let cameraKitInputDidChange = NSNotification.Name("cameraKitInputDidChange")
}
