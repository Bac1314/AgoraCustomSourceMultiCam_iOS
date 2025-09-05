//
//  MultiCameraSourcePushDelegate.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 4/9/25.
//


import UIKit
import AVFoundation
import ObjectiveC.runtime

enum Camera: Int {
    case external = 2
    case front = 1
    case back = 0
    
    static func defaultCamera() -> Camera {
        return .front
    }
    
    func next() -> Camera {
        switch self {
        case .back: return .front
        case .front: return .back
        case .external: return .external
        }
    }
}

private var cameraTagKey: UInt8 = 0

extension AVCaptureConnection {
    var cameraTag: Int? {
        get { return objc_getAssociatedObject(self, &cameraTagKey) as? Int }
        set { objc_setAssociatedObject(self, &cameraTagKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

protocol MultiCameraSourcePushDelegate {
    func myVideoCapture(_ capture: MultiCameraSourcePush,
                        didOutputSampleBuffer pixelBuffer: CVPixelBuffer,
                        from camera: Camera,
                        rotation: Int,
                        timeStamp: CMTime)
}

class MultiCameraSourcePush: NSObject {
    
    fileprivate var delegate: MultiCameraSourcePushDelegate?
    private let captureSession: AVCaptureMultiCamSession
    private let captureQueue: DispatchQueue
    
    init(delegate: MultiCameraSourcePushDelegate?) {
        self.delegate = delegate
        self.captureSession = AVCaptureMultiCamSession()
        self.captureQueue = DispatchQueue(label: "MyMultiCamQueue")
        
        super.init()
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("❌ MultiCam not supported on this device")
            return
        }
        
        print("✅ MultiCam supported")
    }
    
    deinit {
        captureSession.stopRunning()
    }
    
    // MARK: - Public API
    func startCapture() {
        setupMultiCam()
        captureSession.startRunning()
    }
    
    func stopCapture() {
        captureQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    // MARK: - Setup MultiCam
    
    private func setupMultiCam() {
        captureSession.beginConfiguration()
        
        // FRONT
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .video,
                                                     position: .front) {
            addCamera(frontCamera, type: .front)
        }
        
        // BACK
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back) {
            addCamera(backCamera, type: .back)
        }
        
        // EXTERNAL
        if let externalCamera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external],
            mediaType: .video,
            position: .unspecified
        ).devices.first {
            addCamera(externalCamera, type: .external)
        } else {
            print("⚠️ No External Camera detected")
        }
        
        captureSession.commitConfiguration()
    }
    
    private func addCamera(_ device: AVCaptureDevice, type: Camera) {
        guard let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            print("⚠️ Could not add input for \(type)")
            return
        }
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        output.setSampleBufferDelegate(self, queue: captureQueue)
        
        guard captureSession.canAddOutput(output) else {
            print("⚠️ Could not add output for \(type)")
            return
        }
        captureSession.addOutput(output)
        
        // Tag output with camera type via its connection
        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = (type == .front)
//            connection.setValue(type.rawValue, forKey: "CameraTag")
            connection.cameraTag = type.rawValue

        }
        
        print("✅ Added \(type) camera")
    }
}

extension MultiCameraSourcePush: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Identify camera from tagged connection
        let cameraType: Camera
        if let tag = connection.cameraTag,
           let cam = Camera(rawValue: tag) {
            cameraType = cam
        } else {
            cameraType = .back
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.myVideoCapture(self,
                                          didOutputSampleBuffer: pixelBuffer,
                                          from: cameraType,
                                          rotation: 90,
                                          timeStamp: time)
        }
    }
}
