import SwiftUI

struct PresentationAnalyzerView: View {
    @StateObject private var analyzer = PresentationAnalyzerViewModel()
    
    @State private var showReport = false
    @State private var isShowingPresentationAnalyzer = false

    
    
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
                
                
                // ✅ عرض ملاحظة وضع اليد على الرقبة
                if !analyzer.positionText.isEmpty {
                    Text(analyzer.positionText)
                        .font(.title)
                        .bold()
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 50)
                }
                
                Spacer()
                
                // ✅ عرض الوقت بشكل مباشر في الواجهة
                      Text("الوقت: \(formatTime(elapsedTime))")
                          .font(.system(size: 24, weight: .semibold))
                          .foregroundColor(.white)
                          .padding()
                          .background(Color.black.opacity(0.7))
                          .cornerRadius(10)
                          .padding(.top, 20)
                      
                // ✅ عرض العداد لعدد المرات
                Text("عدد مرات لمس الرقبة: \(analyzer.neckTouchCount)")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                
                Button(action: {
                    elapsedTime = Date().timeIntervalSince(startTime)
                    isCameraActive = false // ⭐️ إيقاف الكاميرا عند الذهاب إلى التقرير
                    showReport = true
                }) {
                    Text("انتهاء")
                        .font(.title2)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
                .fullScreenCover(isPresented: $showReport) {
                    ReportView(wrongPostures: getWrongPostures(), elapsedTime: elapsedTime)
                        .onDisappear {
                            print("🔙 Returned from ReportView")
                            resetPresentation() // ⭐️ إعادة ضبط العرض عند العودة
                        }
                }
            }
            .onAppear {
                print("📱 PresentationAnalyzerView appeared")
                startTime = Date()
                startLiveTimer()
                startCountdown() // بدء العداد التنازلي عند العودة من التقرير
            }
            .onDisappear {
                print("📱 PresentationAnalyzerView disappeared")
                isCameraActive = false
                analyzer.stopCamera() // ⭐️ إيقاف الكاميرا عند مغادرة الشاشة
            }
        
        

        
                
                Text(analyzer.handMovementText)
                    .font(.headline)
                    .padding()
                    .background(Color.purple.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 10)

                
                Text("عدد مرات حركة الرأس الزائدة: \(analyzer.headMovementCount)")
                    .font(.headline)
                    .padding()
                    .background(Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 20)

                
                
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
                isCameraActive = true // ⭐️ تفعيل الكاميرا بعد انتهاء العداد التنازلي
                print("🎬 Camera activated!")
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
    
