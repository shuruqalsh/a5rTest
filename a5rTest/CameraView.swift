//
//  CameraView.swift
//  a5rTest
//
//  Created by shuruq alshammari on 05/09/1446 AH.
//
//الاكواد الخاصه في الكاميرا 
import Foundation
import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    let analyzer: PresentationAnalyzerViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        // Request camera permission first
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    analyzer.setupCamera(in: view)
                }
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.frame = UIScreen.main.bounds
        if let previewLayer = analyzer.videoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

