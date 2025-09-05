//
//  UIViewRepresent.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 4/9/25.
//
import Foundation
import SwiftUI
import AVFoundation

struct LocalUIViewRepresent : UIViewRepresentable {
    let containerPreview = LocalVideoPreview()
    
    func makeUIView(context: Context) -> UIView {
        containerPreview.backgroundColor = .darkGray
        containerPreview.layer.cornerRadius = 16
        return containerPreview
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {

    }

}

class LocalVideoPreview: UIView {
//    private var videoWidth: Int = 0
//    private var videoHeight: Int = 0
    private let displayLayer = AVSampleBufferDisplayLayer()

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
//        displayLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(displayLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer.frame = bounds
//        layoutDisplayLayer()
    }
    
//    private func layoutDisplayLayer() {
//        guard videoWidth > 0, videoHeight > 0, !frame.size.equalTo(.zero) else {
//            return
//        }
//        
//        let viewWidth = frame.size.width
//        let viewHeight = frame.size.height
//        let videoRatio = CGFloat(videoWidth) / CGFloat(videoHeight)
//        let viewRatio = viewWidth / viewHeight
//
//        let renderRect = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
//        if !displayLayer.frame.equalTo(renderRect) {
//            displayLayer.frame = renderRect
//        }
//    }
//    

    func display(pixelBuffer: CVPixelBuffer, timeStamp: CMTime) {
        // Timing info
        var timingInfo = CMSampleTimingInfo(
            duration: .zero,
            presentationTimeStamp: timeStamp,
            decodeTimeStamp: .invalid
        )

        // Video format
        var videoFormatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &videoFormatDesc
        )

        guard let formatDesc = videoFormatDesc else { return }

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDesc,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        if let buffer = sampleBuffer {
            displayLayer.enqueue(buffer)
        }
        
    }
}
