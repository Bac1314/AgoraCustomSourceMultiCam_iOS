//
//  AgoraCameraSourcePushDelegate.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 2/9/25.
//



import UIKit
import AVFoundation

protocol AgoraCameraSourcePushDelegate {
    func myVideoCapture(_ capture: AgoraCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime)
}

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

class AgoraCameraSourcePush: NSObject {
    
    fileprivate var delegate: AgoraCameraSourcePushDelegate?
//    private var videoView: UIView // removed this view for now easy implementaiton
    
    private var currentCamera = Camera.defaultCamera()
    private let captureSession: AVCaptureSession
    private let captureQueue: DispatchQueue
    private var currentOutput: AVCaptureVideoDataOutput? {
        if let outputs = self.captureSession.outputs as? [AVCaptureVideoDataOutput] {
            return outputs.first
        } else {
            return nil
        }
    }
    
    init(delegate: AgoraCameraSourcePushDelegate?) {
        self.delegate = delegate
//        self.videoView = videoView
        
        captureSession = AVCaptureSession()
        captureSession.usesApplicationAudioSession = false
        
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        }
        
        captureQueue = DispatchQueue(label: "MyCaptureQueue")
        
        // Set multitasking camera PiP
        if captureSession.isMultitaskingCameraAccessSupported {
            print("Bac's multitask is supported")
            captureSession.isMultitaskingCameraAccessEnabled = true
        }
        
//        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        videoView.insertCaptureVideoPreviewLayer(previewLayer: previewLayer)
    }
    
    deinit {
        captureSession.stopRunning()
    }
    
    func startCapture(ofCamera camera: Camera) {
        guard let currentOutput = currentOutput else {
            return
        }
        
        currentCamera = camera
        currentOutput.setSampleBufferDelegate(self, queue: captureQueue)
        
        captureQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.changeCaptureDevice(toIndex: camera.rawValue, ofSession: strongSelf.captureSession)
            strongSelf.captureSession.beginConfiguration()
            if strongSelf.captureSession.canSetSessionPreset(AVCaptureSession.Preset.vga640x480) {
                strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480
            }
            strongSelf.captureSession.commitConfiguration()
            strongSelf.captureSession.startRunning()
        }
    }
    
    func stopCapture() {
        currentOutput?.setSampleBufferDelegate(nil, queue: nil)
        captureQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func switchCamera() {
        stopCapture()
        currentCamera = currentCamera.next()
        startCapture(ofCamera: currentCamera)
    }
}

private extension AgoraCameraSourcePush {
    func changeCaptureDevice(toIndex index: Int, ofSession captureSession: AVCaptureSession) {
        guard let captureDevice = captureDevice(for: Camera(rawValue: index) ?? .front) else {
            print("⚠️ No capture device found for index \(index)")
            return
        }
        
        let currentInputs = captureSession.inputs as? [AVCaptureDeviceInput]
        let currentInput = currentInputs?.first
        
        if let currentInputName = currentInput?.device.uniqueID,
           currentInputName == captureDevice.uniqueID {
            return // already using this device
        }
        
        guard let newInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        captureSession.beginConfiguration()
        if let currentInput = currentInput {
            captureSession.removeInput(currentInput)
        }
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        }
        captureSession.commitConfiguration()
    }
    
    func captureDevice(for camera: Camera) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,  // built-in (front/back)
            .external          // USB / external cameras
        ]
        
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        
        let devices = discovery.devices
        guard !devices.isEmpty else {
            print("⚠️ No video devices found")
            return nil
        }
        
        switch camera {
        case .front:
            return devices.first(where: { $0.position == .front })
        case .back:
            return devices.first(where: { $0.position == .back })
        case .external:
            return devices.first(where: { $0.position == .unspecified })
        }
    }
}


extension AgoraCameraSourcePush: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }
            
            weakSelf.delegate?.myVideoCapture(weakSelf, didOutputSampleBuffer: pixelBuffer, rotation: 90, timeStamp: time)
        }
    }
}
