import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isShowingPresentation = false
    @State private var glowOpacity = 0.0
    
    // Correct green color
    private let pemoColor = Color(red: 183/255, green: 255/255, blue: 183/255)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                TabView(selection: $currentPage) {
                    // First Page
                    VStack {
                        Spacer()
                            .frame(height: geometry.size.height * 0.3)
                        
                        Text("AI coach\nanalyzes and\nenhances your\nPresentation\nskills in real time")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                        
                        // Page dots
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.bottom, 50)
                    }
                    .tag(0)
                    
                    // Second Page
                    VStack {
                        Spacer()
                            .frame(height: geometry.size.height * 0.15)
                        
                        Text("Record Your\nPresentation !")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Record Yourself, Practice,\nand Get Instant Feedback on\nYour Body Language and\nOratory Skills")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        
                        Spacer()
                            .frame(height: geometry.size.height * 0.15)
                        
                        // Get Started Button
                        Button(action: {
                            isShowingPresentation = true
                        }) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: geometry.size.width * 0.75)
                                .padding(.vertical, 16)
                                .background(
                                    pemoColor
                                        .cornerRadius(30)
                                        .shadow(color: pemoColor.opacity(0.3), radius: 10, x: 0, y: 5)
                                )
                        }
                        
                        Spacer()
                        
                        // Page dots
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.bottom, 50)
                    }
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // PEMO character that moves across pages
                let pemoSize = geometry.size.width * 0.45 // Increased size to match splash screen
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(pemoColor)
                        .frame(width: pemoSize * 1.4)
                        .blur(radius: 30)
                        .opacity(glowOpacity * 0.4)
                    
                    Circle()
                        .fill(pemoColor)
                        .frame(width: pemoSize * 1.2)
                        .blur(radius: 20)
                        .opacity(glowOpacity * 0.3)
                    
                    // Character
                    Group {
                        if currentPage == 1 {
                            Image("PEMO_SMILE")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: pemoSize)
                        } else {
                            Image("PEMO")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: pemoSize)
                        }
                    }
                    .colorMultiply(pemoColor)
                    
                    // Voice and Mic icons for second page
                    if currentPage == 1 {
                        HStack(spacing: 8) {
                            Image("VOICE")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 35)
                                .colorMultiply(pemoColor)
                            
                            Image("MIC")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 35)
                                .colorMultiply(pemoColor)
                        }
                        .offset(x: pemoSize * 0.6)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .position(
                    x: currentPage == 0 ? geometry.size.width * 0.8 : geometry.size.width * 0.25,
                    y: currentPage == 0 ? geometry.size.height * 0.2 : geometry.size.height * 0.8
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
            }
        }
        .fullScreenCover(isPresented: $isShowingPresentation) {
            PresentationAnalyzerView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 1.0
            }
        }
    }
}

#Preview {
    OnboardingView()
}
