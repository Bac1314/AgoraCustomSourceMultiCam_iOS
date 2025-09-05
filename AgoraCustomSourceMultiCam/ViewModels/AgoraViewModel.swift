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
    @Published var agoraChannel = "channel_bac"
    @Published var isJoined = false
    
    // RTC UIDs
    var frontCameraUid: UInt = 123
    var backCameraUid: UInt = 456
    var externalCameraUid: UInt = 789
    
    // RTC Tokens (tokens not needed if project didn't enable certificate)
    var frontCameraUidToken : String?
    var backCameraUidToken : String?
    var externalCameraUidToken : String?
    
    // Custom Video Track IDs
    var frontCameraTrackId: UInt = 0
    var backCameraTrackId: UInt = 0
    var externalCameraTrackId: UInt = 0

     // Delegates
    var frontCameraConnectionDelegator: AgoraMultiDelegator = AgoraMultiDelegator()
    var backCameraConnectionDelegator: AgoraMultiDelegator = AgoraMultiDelegator()
    var externalCameraConnectionDelegator: AgoraMultiDelegator = AgoraMultiDelegator()
    
    var multiCameraSource: MultiCameraSourcePush? // Multi camera source delegator
    
    // Local Views
    var resolutionSize: CGSize = CGSize(width: 720, height: 1280)
    var frontCameraUIView: LocalUIViewRepresent = LocalUIViewRepresent()
    var backCameraUIView: LocalUIViewRepresent = LocalUIViewRepresent()
    var externalCameraUIView: LocalUIViewRepresent = LocalUIViewRepresent()
    
//    var testingUIView: LocalUIViewRepresent2 = LocalUIViewRepresent2()
    
    override init(){
        super.init()
        
        // MARK: Agora Initialization
        let config = AgoraRtcEngineConfig()
        config.appId = agoraAppID
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    
        agoraKit.enableVideo()
        agoraKit.enableAudio()
        
    }
    
    func startMultiCameraStreaming() {
        // Setup custom tracks for Agora SDK
        frontCameraTrackId = UInt(agoraKit.createCustomVideoTrack()) // get track id
        externalCameraTrackId = UInt(agoraKit.createCustomVideoTrack()) // get track id
        backCameraTrackId = UInt(agoraKit.createCustomVideoTrack()) // get track id
        
        // Start multi camera capture
        multiCameraSource = MultiCameraSourcePush(delegate: self)
        multiCameraSource?.startCapture()
        
        // Create 3 connections (uid) to join the same channel
        joinConnectionChannel(uid: frontCameraUid, token: frontCameraUidToken, trackID: frontCameraTrackId, agoraMultiChannelDelegator: frontCameraConnectionDelegator, publishMicrophone: true)
        joinConnectionChannel(uid: backCameraUid, token: backCameraUidToken, trackID: backCameraTrackId, agoraMultiChannelDelegator: backCameraConnectionDelegator, publishMicrophone: false)
        joinConnectionChannel(uid: externalCameraUid, token: externalCameraUidToken , trackID: externalCameraTrackId, agoraMultiChannelDelegator: externalCameraConnectionDelegator, publishMicrophone: false)
    }
    
    func stopMultiCameraStreaming() {
        isJoined = false
        multiCameraSource?.stopCapture()
        multiCameraSource = nil
        
        leaveConnectionChannel(uid: frontCameraUid)
        leaveConnectionChannel(uid: backCameraUid)
        leaveConnectionChannel(uid: externalCameraUid)
        
    }
    
    func joinConnectionChannel(uid: UInt, token: String?, trackID: UInt,  agoraMultiChannelDelegator: AgoraMultiDelegator, publishMicrophone: Bool) {
        // Create connection
        let connection = AgoraRtcConnection()
        connection.channelId = agoraChannel
        connection.localUid = uid

        // Setup delegator
        agoraMultiChannelDelegator.connectionDelegate = self
        agoraMultiChannelDelegator.connectionId = connection

        // Setup media option to send custom video track and microphone track
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.publishCameraTrack = false
        mediaOptions.publishMicrophoneTrack = publishMicrophone // Publish microphone from this connection
        mediaOptions.publishCustomVideoTrack = true
        mediaOptions.customVideoTrackId = Int(trackID)
        mediaOptions.autoSubscribeVideo = false // Autosub false to ensure you don't sub your own streams (aka cost)
        mediaOptions.autoSubscribeAudio = false // Autosub false to ensure you don't sub your own streams (aka cost)
        mediaOptions.clientRoleType = .broadcaster
    
        // Set video encoding resolution
        agoraKit.setVideoEncoderConfigurationEx(AgoraVideoEncoderConfiguration(size: resolutionSize, frameRate: .fps30, bitrate: AgoraVideoBitrateStandard, orientationMode: .adaptative, mirrorMode: .auto), connection: connection)
        
        // Join channel
        agoraKit.joinChannelEx(byToken: token, connection: connection, delegate: agoraMultiChannelDelegator, mediaOptions: mediaOptions)
    }
    
    func leaveConnectionChannel(uid: UInt) {
        let connection = AgoraRtcConnection()
        connection.channelId = agoraChannel
        connection.localUid = uid
        
        agoraKit.leaveChannelEx(connection)

    }
}

//// MARK: Main Agora callbacks
extension AgoraViewModel: AgoraRtcEngineDelegate {
    // When local user joined
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    }
    
    // Local user leaves
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    }
    
}

extension AgoraViewModel: AgoraMultiChannelDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionId: AgoraRtcConnection, didOccurWarning warningCode: AgoraWarningCode) {
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionId: AgoraRtcConnection, didOccurError errorCode: AgoraErrorCode) {
    
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionId: AgoraRtcConnection, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("Bac's didJoinChannel with uid \(uid)")
        if !isJoined {
            isJoined = true
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionId: AgoraRtcConnection, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Bac's remote user joined with uid \(uid) ")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionId: AgoraRtcConnection, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionId: AgoraRtcConnection, tokenPrivilegeWillExpire token: String) {
    }
    
    
}

extension AgoraViewModel: MultiCameraSourcePushDelegate {
    func myVideoCapture(_ capture: MultiCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, from camera: Camera, rotation: Int, timeStamp: CMTime) {
        // Convert custom video data to AgoraVideoFrame
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = AgoraVideoFormat.cvPixelNV12.rawValue

        // Push the AgoraVideoFrame to Agora Channel
        videoFrame.textureBuf = pixelBuffer
        videoFrame.rotation = Int32(rotation)
        // once we have the video frame, we can push to agora sdk
        
////        // OutputVideo
//        let outputVideoFrame = AgoraOutputVideoFrame()
//        outputVideoFrame.width = Int32(resolutionSize.width)
//        outputVideoFrame.height = Int32(resolutionSize.height)
//        outputVideoFrame.pixelBuffer = pixelBuffer
//        outputVideoFrame.rotation = Int32(rotation)
//        
        
        if camera == .front {
            let result = agoraKit.pushExternalVideoFrame(videoFrame, videoTrackId: frontCameraTrackId)
            print("Bac's myVideoCapture camera \(camera) result \(result)")
            
            // Render local view
            Task {
                await MainActor.run {
                    self.frontCameraUIView.containerPreview.display(pixelBuffer: pixelBuffer, timeStamp: timeStamp)
                    //                self.testingUIView.containerPreview.renderVideoPixelBuffer(outputVideoFrame)
                }
            }
        }else if camera == .back {
            let result = agoraKit.pushExternalVideoFrame(videoFrame, videoTrackId: backCameraTrackId)
            print("Bac's myVideoCapture camera \(camera) result \(result)")
            
            // Render local view
            Task {
                await MainActor.run {
                    self.backCameraUIView.containerPreview.display(pixelBuffer: pixelBuffer, timeStamp: timeStamp)
                }
            }
        }else if camera == .external {
            let result = agoraKit.pushExternalVideoFrame(videoFrame, videoTrackId: externalCameraTrackId)
            print("Bac's myVideoCapture camera \(camera) result \(result)")
            
            // Render local view
            Task {
                await MainActor.run {
                    self.externalCameraUIView.containerPreview.display(pixelBuffer: pixelBuffer, timeStamp: timeStamp)
                }
            }
        }
        
    }
    
    
}
