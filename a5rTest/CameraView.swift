//
//  CameraView.swift
//  a5rTest
//
//  Created by shuruq alshammari on 05/09/1446 AH.
//

import Foundation
import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    let analyzer: PresentationAnalyzerViewModel
    let isCameraActive: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isCameraActive {
            print("📸 Starting camera...")
            analyzer.setupCamera(in: uiView) // ✅ تأكيد تشغيل الكاميرا عند الحاجة
        } else {
            print("🛑 Stopping camera...")
            analyzer.stopCamera() // ✅ إيقاف الكاميرا عند عدم الحاجة
        }
    }
}
