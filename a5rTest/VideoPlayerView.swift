//
//  VideoPlayerView.swift
//  a5rTest
//
//  Created by shuruq alshammari on 11/09/1446 AH.
//

import Foundation
import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    
    @Environment(\.presentationMode) var presentationMode // لإغلاق الصفحة
    
    var body: some View {
        ZStack {
            
            VideoPlayer(player: AVPlayer(url: videoURL))
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // ⏪ الرجوع عند الضغط
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}
