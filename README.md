# AgoraCustomSourceMultiCam (iOS)

This project demonstrates how to use the **Agora RTC SDK for iOS** with a **custom video source** to publish video streams from both the **internal iPhone camera** and an **external USB camera** into the same channel. It also shows how to use the **multi-channel connection feature** to manage multiple video sources.

---

## Features

- **Custom Video Source**: Uses `AVCaptureMultiCamSession` and `AVCaptureDeviceInput` to capture raw frames from cameras.
- **Multi-Camera Support**: Publishes both the built-in iPhone front camera, back camera, and an external USB camera at the same time.
- **Multi-Channel Connection**: Demonstrates joining multiple connections with Agora SDK and publishing custom video tracks.

---

## File Overview

| File/Folder                                         | Description                                                                                    |
|-----------------------------------------------------|------------------------------------------------------------------------------------------------|
| `Views/ContentView.swift`                           | The main view to display all the 3 local video streams                                         |
| `Views/LocalUIViewRepresent.swift`                  | SwiftUI/UIView bridge for rendering local video frames using AVSampleBufferDisplayLayer.       |
| `Models/MultiCameraSourcePushDelegate.swift`        | Protocol and delegator for multi-camera video capture and delegation.                          |
| `Models/AgoraMultiChannelDelegate.swift`            | Protocol and delegator for handling multiple Agora channel callbacks.                          |
| `ViewModels/AgoraViewModel.swift`                   | Main view model. Manages Agora engine, channel connections, and custom video track publishing. |
| `Podfile`                                           | CocoaPods dependencies configuration.                                                          |

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
   git clone https://github.com/Bac1314/AgoraCustomSourceMultiCam_iOS.git
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
4. Add your Agora App ID, channel, and token in AgoraViewModel.swift:

   ```swift
    var agoraAppID = ""
    @Published var agoraChannel = "channel_bac"

   // RTC Tokens (tokens not needed if project didn't enable certificate)
    var frontCameraUidToken : String = ""
    var backCameraUidToken : String = ""
    var externalCameraUidToken : String = ""
   ```
   
## Usage
1. Connect an external USB camera to your iPhone.
2. Run the project on a physical iPhone device.
3. Enter a channel name and join.
4. The app will publish streams from:
- **iPhone internal cameras
- **USB external camera
5. Use [https://webdemo-na.agora.io/basicLive/index.html][Agora Web demo] to join the same channel as an audience, you should be able to see the streams 

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
