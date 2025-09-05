//
//  AgoraSampleBufferRender.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 4/9/25.
//


import UIKit
import AVFoundation
import CoreMedia
import CoreVideo
import AgoraRtcKit
import SwiftUI

struct LocalUIViewRepresent2 : UIViewRepresentable {
    let containerPreview = AgoraSampleBufferRender()
    
    func makeUIView(context: Context) -> UIView {
        containerPreview.backgroundColor = .darkGray
        containerPreview.layer.cornerRadius = 16
        return containerPreview
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {

    }

}

class AgoraSampleBufferRender: UIView {
    
    // MARK: - Properties
    private var videoWidth: Int = 0
    private var videoHeight: Int = 0
    
    lazy var displayLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        return layer
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDisplayLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDisplayLayer()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDisplayLayer()
    }
    
    private func setupDisplayLayer() {
        layer.addSublayer(displayLayer)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layoutDisplayLayer()
    }
    
    private func layoutDisplayLayer() {
        guard videoWidth > 0, videoHeight > 0, !frame.size.equalTo(.zero) else {
            return
        }
        
        let viewWidth = frame.size.width
        let viewHeight = frame.size.height
        let videoRatio = CGFloat(videoWidth) / CGFloat(videoHeight)
        let viewRatio = viewWidth / viewHeight
        
//        let videoSize: CGSize
//        if videoRatio >= viewRatio {
//            videoSize = CGSize(width: viewHeight * videoRatio, height: viewHeight)
//        } else {
//            videoSize = CGSize(width: viewWidth, height: viewWidth / videoRatio)
//        }
        
        let renderRect = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        if !displayLayer.frame.equalTo(renderRect) {
            displayLayer.frame = renderRect
        }
    }
    
    // MARK: - Public Methods
    func reset() {
        displayLayer.flushAndRemoveImage()
    }
    
    private func getFormatType(type: Int) -> OSType {
        switch type {
        case 1:
            return kCVPixelFormatType_420YpCbCr8Planar
        case 2:
            return kCVPixelFormatType_32BGRA
        default:
            return kCVPixelFormatType_32BGRA
        }
    }
    
    // MARK: - Video Rendering Methods
    func renderVideoData(_ videoData: AgoraOutputVideoFrame) {
        guard videoData != nil else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.videoWidth = Int(videoData.width)
            self.videoHeight = Int(videoData.height)
            self.layoutDisplayLayer()
        }
        
        let width = Int(videoData.width)
        let height = Int(videoData.height)
        let yStride = Int(videoData.yStride)
        let uStride = Int(videoData.uStride)
        let vStride = Int(videoData.vStride)
        
        let yBuffer = videoData.yBuffer
        let uBuffer = videoData.uBuffer
        let vBuffer = videoData.vBuffer
        
        autoreleasepool {
            var pixelBuffer: CVPixelBuffer?
            let pixelAttributes: [String: Any] = [
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
            let formatType = getFormatType(type: Int(videoData.type))
            
            let result = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                formatType,
                pixelAttributes as CFDictionary,
                &pixelBuffer
            )
            
            guard result == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
                print("Unable to create CVPixelBuffer: \(result)")
                return
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            // Copy Y plane
            let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
            let pixelBufferYBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
            
            if yStride == pixelBufferYBytes {
                memcpy(yPlane, yBuffer, yStride * height)
            } else {
                for i in 0..<height {
                    let srcOffset = yStride * i
                    let dstOffset = pixelBufferYBytes * i
                    memcpy(yPlane?.advanced(by: dstOffset), yBuffer?.advanced(by: srcOffset), min(yStride, pixelBufferYBytes))
                }
            }
            
            // Copy U plane
            let uPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
            let pixelBufferUBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
            
            if uStride == pixelBufferUBytes {
                memcpy(uPlane, uBuffer, uStride * height / 2)
            } else {
                for i in 0..<(height / 2) {
                    let srcOffset = uStride * i
                    let dstOffset = pixelBufferUBytes * i
                    memcpy(uPlane?.advanced(by: dstOffset), uBuffer?.advanced(by: srcOffset), min(uStride, pixelBufferUBytes))
                }
            }
            
            // Copy V plane
            let vPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2)
            let pixelBufferVBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2)
            
            if vStride == pixelBufferVBytes {
                memcpy(vPlane, vBuffer, vStride * height / 2)
            } else {
                for i in 0..<(height / 2) {
                    let srcOffset = vStride * i
                    let dstOffset = pixelBufferVBytes * i
                    memcpy(vPlane?.advanced(by: dstOffset), vBuffer?.advanced(by: srcOffset), min(vStride, pixelBufferVBytes))
                }
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            // Create video format description
            var videoInfo: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
            
            guard let videoFormatDescription = videoInfo else { return }
            
            // Create timing info
            var timingInfo = CMSampleTimingInfo()
            timingInfo.duration = CMTime.zero
            timingInfo.decodeTimeStamp = CMTime.invalid
            timingInfo.presentationTimeStamp = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
            
            // Create sample buffer
            var sampleBuffer: CMSampleBuffer?
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescription: videoFormatDescription,
                sampleTiming: &timingInfo,
                sampleBufferOut: &sampleBuffer
            )
            
            if let sampleBuffer = sampleBuffer {
                displayLayer.enqueue(sampleBuffer)
                if displayLayer.status == .failed {
                    displayLayer.flush()
                }
            }
        }
    }
    
    func renderVideoSampleBuffer(_ sampleBufferRef: CMSampleBuffer, size: CGSize) {
        guard sampleBufferRef != nil else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.videoWidth = Int(size.width)
            self.videoHeight = Int(size.height)
            self.layoutDisplayLayer()
        }
        
        autoreleasepool {
            var timingInfo = CMSampleTimingInfo()
            timingInfo.duration = CMTime.zero
            timingInfo.decodeTimeStamp = CMTime.invalid
            timingInfo.presentationTimeStamp = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
            
            displayLayer.enqueue(sampleBufferRef)
            displayLayer.setNeedsDisplay()
            displayLayer.display()
            layer.display()
        }
    }
    
    func renderVideoPixelBuffer(_ videoData: AgoraOutputVideoFrame) {
        guard videoData != nil else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.videoWidth = Int(videoData.width)
            self.videoHeight = Int(videoData.height)
            self.layoutDisplayLayer()
        }
        
        autoreleasepool {
            let pixelBuffer = videoData.pixelBuffer
            
            // Create video format description
            var videoInfo: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, formatDescriptionOut: &videoInfo)
            
            guard let videoFormatDescription = videoInfo else { return }
            
            // Create timing info
            var timingInfo = CMSampleTimingInfo()
            timingInfo.duration = CMTime.zero
            timingInfo.decodeTimeStamp = CMTime.invalid
            timingInfo.presentationTimeStamp = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
            
            // Create sample buffer
            var sampleBuffer: CMSampleBuffer?
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer!,
                formatDescription: videoFormatDescription,
                sampleTiming: &timingInfo,
                sampleBufferOut: &sampleBuffer
            )
            
            if let sampleBuffer = sampleBuffer {
                displayLayer.enqueue(sampleBuffer)
            }
        }
    }
}
