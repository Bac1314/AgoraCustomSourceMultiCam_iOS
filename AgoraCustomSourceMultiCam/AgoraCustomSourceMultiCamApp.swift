//
//  AgoraCustomSourceMultiCamApp.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 2/9/25.
//

import SwiftUI

@main
struct AgoraCustomSourceMultiCamApp: App {
    @StateObject var agoraVM : AgoraViewModel = AgoraViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(agoraVM)
        }
    }
}
