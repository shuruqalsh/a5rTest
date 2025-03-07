import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var glowOpacity = 0.0
    @State private var showOnboarding = false
    @State private var pemoOffset: CGFloat = 1.0
    @State private var pemoScale: CGFloat = 2.2
    @State private var logoGlow = 0.0
    @State private var logoOpacity = 0.0
    @State private var pemoX: CGFloat = 0.5 // Start at center
    
    // Correct green color to match OnboardingView
    private let pemoColor = Color(red: 183/255, green: 255/255, blue: 183/255)
    
    var body: some View {
        GeometryReader { geometry in
            if showOnboarding {
                OnboardingView()
            } else {
                ZStack {
                    // Background
                    Color.black
                        .ignoresSafeArea()
                    
                    // PEMO character
                    let pemoSize = geometry.size.width * 0.45 // Match onboarding size exactly
                    ZStack {
                        // Enhanced glow effect
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
                        Image("PEMO")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: pemoSize)
                            .colorMultiply(pemoColor)
                    }
                    .scaleEffect(pemoScale)
                    .position(
                        x: geometry.size.width * pemoX,
                        y: geometry.size.height * (0.5 + pemoOffset)
                    )
                    .opacity(isActive ? 1 : 0)
                    
                    // PRZNT Text with glow effect
                    ZStack {
                        // Outer glow
                        Text("PRZNT")
                            .font(.system(size: 55, weight: .bold))
                            .foregroundColor(.white)
                            .blur(radius: 20)
                            .opacity(logoGlow)
                        
                        // Inner glow
                        Text("PRZNT")
                            .font(.system(size: 55, weight: .bold))
                            .foregroundColor(.white)
                            .blur(radius: 10)
                            .opacity(logoGlow * 0.8)
                        
                        // Main text
                        Text("PRZNT")
                            .font(.system(size: 55, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(y: -geometry.size.height * 0.2)
                    .opacity(logoOpacity)
                }
                .onAppear {
                    // Initial animations
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        glowOpacity = 1.0
                    }
                    
                    // Fade in everything
                    withAnimation(.easeOut(duration: 0.5)) {
                        isActive = true
                        logoOpacity = 1.0
                    }
                    
                    // Animate logo glow
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatCount(3, autoreverses: true)
                    ) {
                        logoGlow = 0.8
                    }
                    
                    // Slide up to center
                    withAnimation(
                        .spring(response: 1.2, dampingFraction: 0.7)
                        .delay(0.2)
                    ) {
                        pemoOffset = 0.0 // Center vertically
                        pemoScale = 1.8 // Keep large while centered
                    }
                    
                    // Wait in center, then move to final position
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        // Fade out logo
                        withAnimation(.easeOut(duration: 0.4)) {
                            logoOpacity = 0
                        }
                        
                        // Move PEMO to exact onboarding position
                        withAnimation(
                            .spring(response: 0.7, dampingFraction: 0.8)
                        ) {
                            pemoScale = 1.0
                            pemoX = 0.8 // Match onboarding x position
                            pemoOffset = -0.3 // Match onboarding y position
                        }
                        
                        // Transition to onboarding
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showOnboarding = true
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
} 