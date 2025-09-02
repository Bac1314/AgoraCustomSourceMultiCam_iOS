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
    
    var internalCameraUid: UInt = UInt.random(in: 1...99999)
    var externalCameraUid: UInt = UInt.random(in: 100000...9999999)
    
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
    
    
//    func agoraSetupCanvas(view: UIView, uid: UInt, deviceID: String?) {
//        if deviceID != nil {
//            // Enable external camera capture
//            let cameraCaptureConfig = AgoraCameraCapturerConfiguration()
//            cameraCaptureConfig.deviceId = deviceID
//            agoraKit.enableMultiCamera(true, config: cameraCaptureConfig)
//            agoraKit.startCameraCapture(.cameraSecondary, config: cameraCaptureConfig)
//        }
//        
//        // set up canvas to render video streams
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = uid
//        videoCanvas.view = view
//        videoCanvas.renderMode = .hidden
//        
//        if uid == internalCameraUid || uid == externalCameraUid {
//            // Setup local view
//            videoCanvas.sourceType = uid == internalCameraUid ? .camera : .cameraSecondary
//            agoraKit.setupLocalVideo(videoCanvas)
//            agoraKit.startPreview()
//        }else {
//            // Setup remote view
//            agoraKit.setupRemoteVideo(videoCanvas)
//        }
//    }
    
    // Use
    func joinChannelInternalCamera() {
        
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.publishCameraTrack = true
        mediaOptions.publishMicrophoneTrack = true
        mediaOptions.autoSubscribeVideo = false
        mediaOptions.autoSubscribeAudio = false
        mediaOptions.clientRoleType = .broadcaster
        
        agoraKit.joinChannel(byToken: nil, channelId: agoraChannel, uid: internalCameraUid, mediaOptions: mediaOptions)
    }
    
    func joinChannelExternalCamera() {
        let connection = AgoraRtcConnection()
        connection.channelId = agoraChannel
        connection.localUid = externalCameraUid

        let mediaOptions = AgoraRtcChannelMediaOptions()
        // publish audio and camera track for channel 1
        mediaOptions.publishCameraTrack = false
        mediaOptions.publishMicrophoneTrack = false
        mediaOptions.publishSecondaryCameraTrack = true
        mediaOptions.autoSubscribeVideo = false
        mediaOptions.autoSubscribeAudio = false
        mediaOptions.clientRoleType = .broadcaster
        
        agoraKit.joinChannelEx(byToken: nil, connection: connection, delegate: self, mediaOptions: mediaOptions)
    }
    
    func agoraSetupRemoteVideo(connection: AgoraRtcConnection, remoteID: UInt, remoteView: UIView, streamType: AgoraVideoStreamType) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = remoteID
        videoCanvas.renderMode = .hidden
        videoCanvas.view = remoteView
        agoraKit.setupRemoteVideoEx(videoCanvas, connection: connection)
        agoraKit.setRemoteVideoStreamEx(remoteID, type: streamType, connection: connection)
    }
    
    func setupBuiltInCamera() {
         // Create video source for built-in camera
        builtInCameraSource = AgoraCameraSourcePush(delegate: self)
        builtInCameraSource?.startCapture(ofCamera: .front)
        
     }
    
    func setupExternalCamera() {
         // Create video source for built-in camera
        externalCameraSource = AgoraCameraSourcePush(delegate: self)
        externalCameraSource?.startCapture(ofCamera: .external)
        
     }
     
     
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
extension AgoraViewModel: AgoraRtcEngineDelegate, AgoraCameraSourcePushDelegate {
    // When local user joined
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    }
    
    // Local user leaves
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    }
    
    
    func myVideoCapture(_ capture: AgoraCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        
    }
}
