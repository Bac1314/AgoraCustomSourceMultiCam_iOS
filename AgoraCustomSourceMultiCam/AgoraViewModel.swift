//
//  AgoraViewModel.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 2/9/25.
//

import Foundation
import AgoraRtcKit
import AVFoundation

class AgoraViewModel: NSObject, ObservableObject {
    
    // MARK: AGORA PROPERTIES
    var agoraKit: AgoraRtcEngineKit = AgoraRtcEngineKit()
    var agoraAppID = ""
    var agoraChannel = "channel_bac"
    
    var builtInCameraUid: UInt = UInt.random(in: 1...99999)
    var externalCameraUid: UInt = UInt.random(in: 100000...9999999)
    
    var builtInCameraTrackId: UInt32 = 0
    var externalCameraTrackId: UInt32 = 0

    var builtInCameraSource: AgoraCameraSourcePush?
    var externalCameraSource: AgoraCameraSourcePush?
    
    
    override init(){
        super.init()
        
        // MARK: Agora Initialization
        let config = AgoraRtcEngineConfig()
        config.appId = agoraAppID
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit.setChannelProfile(.liveBroadcasting)
        agoraKit.setClientRole(.broadcaster, options: AgoraClientRoleOptions())
        
        agoraKit.enableVideo()
        agoraKit.enableAudio()
    }
    
    
    func setupBuiltInCamera() {
        var customSourceDelegator: CustomVideoSourceMultiChannelDelegator = CustomVideoSourceMultiChannelDelegator()
        customSourceDelegator.cameraType = .front
        
         // Create video source for built-in camera
        builtInCameraSource = AgoraCameraSourcePush(delegate: customSourceDelegator)
        builtInCameraSource?.startCapture(ofCamera: .front)
        builtInCameraTrackId = agoraKit.createCustomVideoTrack() // get track id
     }
    
    func setupExternalCamera() {
        var customSourceDelegator: CustomVideoSourceMultiChannelDelegator = CustomVideoSourceMultiChannelDelegator()
        customSourceDelegator.cameraType = .external
        
         // Create video source for external camera
        externalCameraSource = AgoraCameraSourcePush(delegate: customSourceDelegator)
        externalCameraSource?.startCapture(ofCamera: .external)
        externalCameraTrackId = agoraKit.createCustomVideoTrack() // get track id
     }
     
    func joinChannelInternalCamera() {
        
        // Create connection
        let connection = AgoraRtcConnection()
        connection.channelId = agoraChannel
        connection.localUid = builtInCameraUid

        // Setup media option to send custom video track and microphone track
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.publishCameraTrack = false
        mediaOptions.publishMicrophoneTrack = true
        mediaOptions.publishCustomVideoTrack = true
        mediaOptions.customVideoTrackId = Int(builtInCameraTrackId)
        mediaOptions.autoSubscribeVideo = false
        mediaOptions.autoSubscribeAudio = false
        mediaOptions.clientRoleType = .broadcaster
        
        agoraKit.joinChannelEx(byToken: nil, connection: connection, delegate: self, mediaOptions: mediaOptions)
    }
    
    func joinChannelExternalCamera() {
        // Create connection
        let connection = AgoraRtcConnection()
        connection.channelId = agoraChannel
        connection.localUid = builtInCameraUid

        // Setup media option to send custom video track ONLY
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.publishCameraTrack = false
        mediaOptions.publishMicrophoneTrack = false
        mediaOptions.publishCustomVideoTrack = true
        mediaOptions.customVideoTrackId = Int(externalCameraTrackId)
        mediaOptions.autoSubscribeVideo = false
        mediaOptions.autoSubscribeAudio = false
        mediaOptions.clientRoleType = .broadcaster
        
        agoraKit.joinChannelEx(byToken: nil, connection: connection, delegate: self, mediaOptions: mediaOptions)
    }
    
//    func agoraSetupRemoteVideo(connection: AgoraRtcConnection, remoteID: UInt, remoteView: UIView, streamType: AgoraVideoStreamType) {
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = remoteID
//        videoCanvas.renderMode = .hidden
//        videoCanvas.view = remoteView
//        agoraKit.setupRemoteVideoEx(videoCanvas, connection: connection)
//        agoraKit.setRemoteVideoStreamEx(remoteID, type: streamType, connection: connection)
//    }
//     
//    func setupExternalCamera() {
//         // Create video source for external camera
//         externalCameraSource = AgoraCameraVideoSource()
//         
//         // Try to find external camera (USB connected camera)
//         let externalCamera = findExternalCamera()
//         
//         if let camera = externalCamera {
//             externalCameraSource.setDevice(camera)
//             
//             // Create video track for external camera
//             let videoTrack = agoraKit.createCustomVideoTrack(withVideoSource: externalCameraSource,
//                                                             config: createVideoConfig())
//             
//             // Set track ID
//             videoTrack?.setVideoTrackId(externalCameraTrackId)
//             
//             // Create local video canvas for external camera
//             let externalCanvas = AgoraRtcVideoCanvas()
//             externalCanvas.uid = 0
//             externalCanvas.view = externalCameraView
//             externalCanvas.renderMode = .fit
//             externalCanvas.sourceType = .videoTrack
//             externalCanvas.videoTrackId = externalCameraTrackId
//             
//             agoraKit.setupLocalVideo(externalCanvas)
//         } else {
//             print("No external camera found")
//             // Fallback to rear camera if no external camera
//             setupRearCameraAsExternal()
//         }
//     }
//     
//    func setupRearCameraAsExternal() {
//         // Fallback: Use rear camera as "external" camera
//         let rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
//                                                 for: .video,
//                                                 position: .back)
//         
//         if let camera = rearCamera {
//             externalCameraSource.setDevice(camera)
//             
//             let videoTrack = agoraKit.createCustomVideoTrack(withVideoSource: externalCameraSource,
//                                                             config: createVideoConfig())
//             videoTrack?.setVideoTrackId(externalCameraTrackId)
//             
//             let externalCanvas = AgoraRtcVideoCanvas()
//             externalCanvas.uid = 0
//             externalCanvas.view = externalCameraView
//             externalCanvas.renderMode = .fit
//             externalCanvas.sourceType = .videoTrack
//             externalCanvas.videoTrackId = externalCameraTrackId
//             
//             agoraKit.setupLocalVideo(externalCanvas)
//         }
//     }
//     
//     private func findExternalCamera() -> AVCaptureDevice? {
//         // Look for external USB cameras
//         let discoverySession = AVCaptureDevice.DiscoverySession(
//             deviceTypes: [.external],
//             mediaType: .video,
//             position: .unspecified
//         )
//         
//         return discoverySession.devices.first
//     }
     
    
}


//// MARK: Main Agora callbacks
extension AgoraViewModel: AgoraRtcEngineDelegate {
    // When local user joined
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    }
    
    // Local user leaves
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    }
    
    
    func myVideoCapture(_ capture: AgoraCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        
    }
}


extension AgoraViewModel: CustomVideoSourceMultiChannelDelegate {
    func captureOutput(cameraType: Camera, _ capture: AgoraCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        
        // Convert custom video data to AgoraVideoFrame
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = AgoraVideoFormat.cvPixelNV12.rawValue

        // Push the AgoraVideoFrame to Agora Channel
        videoFrame.textureBuf = pixelBuffer
        videoFrame.rotation = Int32(rotation)
        // once we have the video frame, we can push to agora sdk
        let result = agoraKit.pushExternalVideoFrame(videoFrame, videoTrackId: cameraType == .front ? builtInCameraUid : externalCameraUid)
        print("Bac's pushExternal result \(result)")
        
    }
    
}

