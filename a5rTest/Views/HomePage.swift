import SwiftUI

struct HomePage: View {
    private let pemoColor = Color(hex: "#CFF39A")
    @State private var isShowingPresentationAnalyzer = false
    
    @State private var isShowingOnboardingView = false // ✅ حالة لعرض صفحة OnboardingView
    
    var body: some View {
        ZStack {
            // الخلفية
            Color(hex: "#141F25")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // الزر العلوي في الزاوية اليمنى
                HStack {
                    Spacer()
                    Button(action: {                        isShowingOnboardingView = true // ✅ عند الضغط يفتح صفحة OnboardingView

                        // أضف الأكشن هنا
                    }) {
                        Image("QuestionMark")
                            .foregroundColor(pemoColor)
                            .font(.system(size: 30))
                            .padding()
                    }
                }
                
                Spacer()
                
                // النص الرئيسي
                Text("Ready to Practice Your Presentation?")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(width: 317, alignment: .leading ) // تحديد عرض الفريم مع محاذاة لليسار
                    .padding(.leading, -40)
                
                
                HStack(spacing: 16) {
                        // زر الكارد الأول (Full Performance Review)
                        Button(action: {
                            print("Full Performance Review Button Tapped")
                            isShowingPresentationAnalyzer = true
                        }) {
                            practiceCard(title: "Full Performance\nReview", cameraIcon: true)
                        }
                        
                        // زر الكارد الثاني (Oratory Evaluation only)
                        Button(action: {
                            print("Oratory Evaluation Button Tapped")
                        }) {
                            practiceCard(title: "Oratory Evaluation\nonly", cameraIcon: false)
                        }
                    }
                
                       // عرض صفحة PresentationAnalyzerView
                       .fullScreenCover(isPresented: $isShowingPresentationAnalyzer) {
                           PresentationAnalyzerView()
                       }
                       
                       // عرض صفحة OnboardingView
                       .fullScreenCover(isPresented: $isShowingOnboardingView) {
                           OnboardingView()
                       }
                   
            
                Spacer()
                
                // النص السفلي
                Text("By using the app, you agree to")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .padding(.bottom, 5)
                
                Button(action: {
                    // رابط سياسة الخصوصية
                }) {
                    Text("our Privacy Policy")
                        .foregroundColor(.purple)
                        .font(.system(size: 14))
                }
                
                Spacer()
                    .frame(height: 30)
            }
            .padding(.horizontal, 24) // ✅ أضفنا البادينق لكل العناصر في الـ VStack
        }
    }
    
    // دالة لإنشاء الكارد بدون تأثير على الترتيب
        func practiceCard(title: String, cameraIcon: Bool) -> some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 160, height: 220)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 5) {
                        if cameraIcon {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Image(systemName: "mic.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    
                    Spacer()
                    
                    // صورة بيمو
                    Image("HomePagePemo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160)
                        .offset(x: -10 , y: -67)
                }
                .padding(10)
            }
        }
    }

    #Preview {
        HomePage()
    }
