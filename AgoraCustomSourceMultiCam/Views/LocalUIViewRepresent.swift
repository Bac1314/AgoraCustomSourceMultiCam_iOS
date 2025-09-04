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
    private let displayLayer = AVSampleBufferDisplayLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        displayLayer.videoGravity = .resizeAspectFill
//        displayLayer.cornerRadius = 16
        layer.addSublayer(displayLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer.frame = bounds
    }

    func display(pixelBuffer: CVPixelBuffer, timeStamp: CMTime) {
        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: timeStamp,
            decodeTimeStamp: .invalid
        )

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
