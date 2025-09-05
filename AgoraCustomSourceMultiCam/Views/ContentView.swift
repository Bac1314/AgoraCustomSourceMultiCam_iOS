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
            
            if !agoraVM.isJoined {
                Text("Multi Camera Streaming")
                    .bold()
                    .font(.title2)
                    .padding(.bottom, 36)
                
                TextField("Enter channel name", text: $agoraVM.agoraChannel)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.gray, lineWidth: 1.0)
                    )
                
                
                Text("Start Multi-cam Streaming")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(Color.white)
                    .background(agoraVM.agoraChannel.isEmpty ? Color.gray : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(agoraVM.agoraChannel.isEmpty)
                    .onTapGesture {
                        agoraVM.startMultiCameraStreaming()
                    }

            } else {
                Text("Local Views")
                    .font(.headline)
                
                agoraVM.frontCameraUIView
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                agoraVM.backCameraUIView
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                agoraVM.externalCameraUIView
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
//                agoraVM.testingUIView
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                
                Text("Stop Streaming")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(Color.white)
                    .background(agoraVM.agoraChannel.isEmpty ? Color.gray : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture {
                        agoraVM.stopMultiCameraStreaming()
                    }
            }
            
        }
        .padding()
    }
    

 
}

#Preview {
    ContentView()
        .environmentObject(AgoraViewModel())
}
