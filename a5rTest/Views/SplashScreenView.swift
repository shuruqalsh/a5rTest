import SwiftUI

struct ShootingStar: View {
    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0
    
    let startPoint: CGPoint
    let duration: Double
    let delay: Double
    let angle: Double
    
    var body: some View {
        // Star with trail effect
        HStack(spacing: 0) {
            // Trail
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.white, .white.opacity(0)]),
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: 30, height: 1.5)
                .blur(radius: 0.5)
            
            // Main star
            Circle()
                .fill(Color.white)
                .frame(width: 2.5, height: 2.5)
                .blur(radius: 0.5)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .blur(radius: 1)
                        .opacity(0.9)
                )
        }
        .rotationEffect(.degrees(angle))
        .position(startPoint)
        .offset(offset)
        .opacity(opacity)
        .onAppear {
            let distance = UIScreen.main.bounds.width * 1.5
            let dx = cos(angle * .pi / 180) * distance
            let dy = sin(angle * .pi / 180) * distance
            
            withAnimation(
                .easeOut(duration: duration)
                .delay(delay)
                .repeatForever(autoreverses: false)
            ) {
                offset = CGSize(width: dx, height: dy)
                opacity = 0.8
            }
            
            withAnimation(
                .easeIn(duration: duration * 0.3)
                .delay(delay + duration * 0.7)
                .repeatForever(autoreverses: false)
            ) {
                opacity = 0
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var glowOpacity = 0.0
    @State private var showOnboarding = false
    @State private var pemoOffset: CGFloat = 1.0
    @State private var pemoScale: CGFloat = 2.2
    @State private var logoGlow = 0.0
    @State private var logoOpacity = 0.0
    @State private var pemoX: CGFloat = 0.5 // Start at center
    
    // Updated shooting star positions with consistent direction and better coverage
    private let shootingStars: [(point: CGPoint, duration: Double, delay: Double, angle: Double)] = [
        // Top section stars
        (CGPoint(x: -30, y: 0), 2.0, 0.0, 45),
        (CGPoint(x: -25, y: 100), 1.8, 1.2, 43),
        
        // Middle section stars
        (CGPoint(x: -20, y: UIScreen.main.bounds.height * 0.4), 2.2, 0.6, 45),
        (CGPoint(x: -35, y: UIScreen.main.bounds.height * 0.5), 1.9, 1.8, 44),
        
        // Bottom section stars
        (CGPoint(x: -15, y: UIScreen.main.bounds.height * 0.7), 2.1, 0.3, 46),
        (CGPoint(x: -25, y: UIScreen.main.bounds.height * 0.9), 2.0, 1.5, 45)
    ]
    
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
                    
                    // Shooting Stars
                    ForEach(0..<shootingStars.count, id: \.self) { index in
                        let star = shootingStars[index]
                        ShootingStar(
                            startPoint: star.point,
                            duration: star.duration,
                            delay: star.delay,
                            angle: star.angle
                        )
                    }
                    
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