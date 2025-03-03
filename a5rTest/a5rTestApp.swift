//
//  a5rTestApp.swift
//  a5rTest
//
//  Created by shuruq alshammari on 26/08/1446 AH.
//

import SwiftUI

@main
struct a5rTestApp: App {
    var body: some Scene {
        WindowGroup {
            PresentationAnalyzerView()
        }
    }
}

// Bridge between SwiftUI and UIKit
struct PresentationAnalyzerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PresentationAnalyzerViewController {
        return PresentationAnalyzerViewController()
    }
    
    func updateUIViewController(_ uiViewController: PresentationAnalyzerViewController, context: Context) {
        // Updates can be handled here if needed
    }
}
