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
        let view = UIView()
        analyzer.setupCamera(in: view)
        view.backgroundColor = .clear
        return view
        
        
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

