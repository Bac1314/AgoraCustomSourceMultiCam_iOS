//
//  CustomVideoSourceMultiChannelDelegate.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 3/9/25.
//

import Foundation
import AVFoundation

// Multi channel delegate protocol
protocol CustomVideoSourceMultiChannelDelegate: NSObject {
    func captureOutput(cameraType: Camera, _ capture: AgoraCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime)
}



// Multi channel delegator
class CustomVideoSourceMultiChannelDelegator: NSObject, AgoraCameraSourcePushDelegate {

    weak var connectionDelegate: CustomVideoSourceMultiChannelDelegate?
    var cameraType: Camera?
    
    func myVideoCapture(_ capture: AgoraCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        if let camera = cameraType {
            self.connectionDelegate?.captureOutput(cameraType: camera, capture, didOutputSampleBuffer: pixelBuffer, rotation: rotation, timeStamp: timeStamp)
        }
    }
}
