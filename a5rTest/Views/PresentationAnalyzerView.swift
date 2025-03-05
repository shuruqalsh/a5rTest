//
//  PresentationAnalyzerView.swift
//  a5rTest
//
//  Created by shuruq alshammari on 05/09/1446 AH.
//
// الكود الخاص بواجهة الكاميرا
import Foundation
import SwiftUI

struct PresentationAnalyzerView: View {
    @StateObject private var analyzer = PresentationAnalyzerViewModel()
    
    var body: some View {
        ZStack {
            CameraView(analyzer: analyzer)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text(analyzer.positionText)
                    .font(.title)
                    .bold()
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 50)
                
                Spacer()
                
                Text(analyzer.feedbackText)
                    .font(.body)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                
                
                
            }
        }
    }
}
