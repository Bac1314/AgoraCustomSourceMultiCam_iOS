//
//  ContentView.swift
//  AgoraCustomSourceMultiCam
//
//  Created by Bac Huang on 2/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var agoraVM: AgoraViewModel
    
    var body: some View {
        VStack {
            Text("Local Views")
                .font(.headline)
            
            agoraVM.frontCameraUIView
            agoraVM.backCameraUIView
            agoraVM.externalCameraUIView
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AgoraViewModel())
}
