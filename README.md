# AgoraCustomSourceMultiCam (iOS)

This project demonstrates how to use the **Agora RTC SDK for iOS** with a **custom video source** to publish video streams from both the **internal iPhone camera** and an **external USB camera** into the same channel. It also shows how to use the **multi-channel connection feature** to manage multiple video sources.

---

## Features

- **Custom Video Source**: Uses `AVCaptureSession` and `AVCaptureDeviceInput` to capture raw frames from cameras.
- **Multi-Camera Support**: Publishes both the built-in iPhone camera and an external USB camera.
- **Multi-Channel Connection**: Demonstrates joining multiple connections with Agora SDK and publishing custom video tracks.
- **Flexible Pipeline**: Developers can extend to include filters, beauty, or third-party processing.

---

## Requirements

- **Xcode 15.0 or later**  
- **iOS 14.0 or later**  
- **Physical iPhone device** (multi-camera capture is not supported in Simulator)  
- **External USB camera** (via Lightning/USB-C adapter)  
- **Agora RTC iOS SDK 4.6.0** (installed via CocoaPods)  

---

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/AgoraCustomSourceMultiCam.git
   cd AgoraCustomSourceMultiCam
   ```
   
2. Install dependencies:

   ```bash
    pod install
   ```
3. Open the workspace:

   ```bash
    open AgoraCustomSourceMultiCam.xcworkspace
   ```
4. Add your Agora App ID and Token in AppID.swift:

   ```swift
let agoraAppId: String = "<#Your App ID#>"
let agoraToken: String? = "<#Your Token#>"
   ```
   
## Usage
1. Connect an external USB camera to your iPhone.
2. Run the project on a physical iPhone device.
3. Enter a channel name and join.
4. The app will publish streams from:
- **iPhone internal camera
- **USB external camera

Both streams will be visible to remote participants in the same channel.

## Notes
- ** Multi-camera capture may increase CPU/GPU load and network bandwidth usage.
- ** USB cameras must support UVC (USB Video Class).
- ** Only real devices are supported. iOS Simulator cannot access cameras.

## Reference
[https://docs.agora.io/en/interactive-live-streaming/get-started/get-started-sdk?platform=ios][Agora iOS SDK Documentation]
[https://developer.apple.com/av-foundation][AVFoundation Programming Guide]

## License
This project is provided for educational/demo purposes under the MIT License. See `LICENSE.txt` for more information.
