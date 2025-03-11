import SwiftUI
import AVFoundation
import UIKit
import AVFoundation
import Vision
import CoreGraphics

struct PresentationAnalyzerView: View {
    @StateObject private var analyzer = PresentationAnalyzerViewModel()
    
    @State private var showReport = false
    @State private var isShowingPresentationAnalyzer = false

    
       private var captureSession: AVCaptureSession?
       private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
       private var videoOutput = AVCaptureMovieFileOutput()
    
       
    
    @State private var startTime: Date = Date() // 🆕 وقت البداية
    @State private var elapsedTime: TimeInterval = 0 // 🆕 الوقت المستغرق
    
    @State private var isCameraActive = false // ⭐️ حالة تشغيل الكاميرا فقط عند الحاجة
    @State private var countdown = 3 // ⭐️ العداد التنازلي لبدء التحليل
    @State private var showCountdown = false // ⭐️ عرض العداد التنازلي
    
    
    
    
    var body: some View {
        ZStack {
            if isCameraActive {
                    CameraView(analyzer: analyzer, isCameraActive: isCameraActive)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            print("👀 CameraView appeared")
                        }
                        .onDisappear {
                            print("👋 CameraView disappeared")
                            analyzer.stopCamera() // ⭐️ تأكد من إيقاف الكاميرا عند مغادرة الشاشة بالكامل
                        }
                }
       
            VStack {
                
                
   
                
                Spacer()
                
                // ✅ عرض العداد التنازلي في الواجهة
                if showCountdown {
                    Text(" \(countdown)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.top, 20)
                } else {
                    // ✅ عرض الوقت المستغرق فقط بعد انتهاء العداد التنازلي
                    Text("\(formatTime(elapsedTime))")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .frame(width: 80, height: 80)

                        .cornerRadius(10)
                        .padding(.top, 20)
                }
                
                      
                Button(action: {
                       if analyzer.videoURL == nil {
                           analyzer.startRecording() // 🎥 بدء التسجيل
                       } else {
                           analyzer.stopRecording() // ⏹️ إيقاف التسجيل
                       }
                   }) {
                       Image(systemName: analyzer.videoURL == nil ? "record.circle.fill" : "stop.circle.fill")
                           .resizable()
                           .frame(width: 60, height: 60)
                           .foregroundColor(analyzer.videoURL == nil ? .red : .gray)
                           .padding()
                           .background(Color.white.opacity(0.7))
                           .clipShape(Circle())
                   }
               
                
                Button(action: {
                    elapsedTime = Date().timeIntervalSince(startTime)
                    isCameraActive = false // ⭐️ إيقاف الكاميرا عند الذهاب إلى التقرير
                    showReport = true
                }) {
                    Image("done")
                        .padding()
                        .background(Color(hex: "#38464F"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
                .fullScreenCover(isPresented: $showReport) {
                        ReportView(
                            wrongPostures: getWrongPostures(),
                            videoURL: analyzer.videoURL,
                            elapsedTime: elapsedTime)

                        .onDisappear {
                            print("🔙 Returned from ReportView")
                            resetPresentation() // ⭐️ إعادة ضبط العرض عند العودة
                        }
                }
            }
            .onAppear {
                print("📱 PresentationAnalyzerView appeared")
                startCountdown()  // ✅ بدء العداد التنازلي مباشرة عند الظهور
            }
            .onDisappear {
                print("📱 PresentationAnalyzerView disappeared")
                isCameraActive = false
                analyzer.stopCamera() // ⭐️ إيقاف الكاميرا عند مغادرة الشاشة
            }
        
        

        
                
             

                
                
                // ✅ عرض النص التعقيبي
                if !analyzer.feedbackText.isEmpty {
                    Text(analyzer.feedbackText)
                        .font(.body)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                }
            }
        }
    // ⭐️ دالة لإعادة تعيين كل شيء عند العودة من صفحة التقرير
    private func resetPresentation() {
        print("🔄 Resetting presentation")
        elapsedTime = 0
        analyzer.neckTouchCount = 0
        analyzer.headMovementCount = 0
        startTime = Date()
        startCountdown()
        analyzer.videoURL = nil // ✅ السماح بالتسجيل مرة أخرى

    }
    
    private func startCountdown() {
        countdown = 3
        showCountdown = true
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                showCountdown = false
                isCameraActive = true
                startTime = Date() // 🕒 بدء حساب الوقت بعد انتهاء العد التنازلي
                startLiveTimer() // 🕒 تشغيل المؤقت المباشر
                print("🎬 Camera activated and timer started!")

                // ✅ بعد انتهاء العد التنازلي → ابدأ التسجيل تلقائيًا
                analyzer.startRecording()
            }
        }
    }

    
    
    private func startLiveTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            elapsedTime = Date().timeIntervalSince(startTime)
            if showReport {
                timer.invalidate() // 🚦 وقف التايمر عند الخروج للـ ReportView
            }
        }
    }
    // 🆕 دالة لتحويل الوقت المستغرق إلى صيغة "دقائق:ثواني"
        private func formatTime(_ time: TimeInterval) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%01d:%02d", minutes, seconds)
        }
    

    
    // 🆕 دالة للحصول على الوضعيات الخاطئة
    private func getWrongPostures() -> [Posture] {
        var wrongPostures: [Posture] = []
        
        // مثال: إضافة الوضعيات الخاطئة بناءً على البيانات الموجودة في الـ ViewModel
        if analyzer.neckTouchCount > 0 {
            wrongPostures.append(Posture(name: "لمس الرقبة", correctImage: "correct1", wrongImage: "wrong1"))
        }
        
        if analyzer.headMovementCount > 0 {
            wrongPostures.append(Posture(name: "You are not looking at the audience enough! Try to engage with the audience more.", correctImage: " headMovementRight", wrongImage: "wrong2"))
        }
        
        // إضافة المزيد من الوضعيات الخاطئة بناءً على الحالات الأخرى
        return wrongPostures
    }
}
    
#Preview {
    PresentationAnalyzerView()
}
