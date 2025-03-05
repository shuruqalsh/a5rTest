//
//  PresentationAnalyzerView.swift
//  a5rTest
//
//  Created by shuruq alshammari on 05/09/1446 AH.
//
// الكود الخاص بواجهة الكاميرا
import Foundation
import SwiftUI
import AVFoundation

struct PresentationAnalyzerView: View {
    @StateObject private var analyzer = PresentationAnalyzerViewModel()
    @State private var isPermissionGranted = false
    
    var body: some View {
        ZStack {
            if isPermissionGranted {
                CameraView(analyzer: analyzer)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if !analyzer.cameraError.isEmpty {
                        Text(analyzer.cameraError)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.top, 50)
                    }
                    
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
            } else {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                Text("Camera access is required")
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isPermissionGranted = granted
                }
            }
        default:
            isPermissionGranted = false
        }
    }
}
