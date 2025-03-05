import SwiftUI

struct ShootingStar: View {
    let startPoint: CGPoint
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 2, height: 2)
            .blur(radius: 0.5)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 15, height: 1.5)
                    .blur(radius: 0.5)
                    .offset(x: -8)
            )
            .position(startPoint)
            .offset(x: offset.width, y: offset.height)
            .opacity(opacity)
            .onAppear {
                let randomDelay = Double.random(in: 0...3)
                withAnimation(
                    .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(randomDelay)
                ) {
                    offset = CGSize(width: UIScreen.main.bounds.width + 100, height: UIScreen.main.bounds.width + 100)
                    opacity = Double.random(in: 0.6...1.0)
                }
            }
    }
}

struct SplashScreenView: View {
    // Animation states
    @State private var isLogoVisible = false
    @State private var characterOffset: CGFloat = 200
    @State private var shouldShowMainApp = false
    @State private var glowOpacity: Double = 0
    
    // Animation timing constants
    private let logoAnimationDuration: Double = 0.8
    private let logoAnimationDelay: Double = 0.3
    private let characterAnimationDelay: Double = 0.5
    private let transitionDelay: Double = 2.5
    
    // Star positions
    private let starPositions: [CGPoint] = [
        CGPoint(x: -20, y: 20),
        CGPoint(x: -10, y: 60),
        CGPoint(x: 30, y: 10),
        CGPoint(x: 50, y: 40),
        CGPoint(x: 80, y: 15),
        CGPoint(x: 120, y: 30),
        CGPoint(x: 150, y: 20),
        CGPoint(x: 180, y: 45),
        CGPoint(x: 220, y: 25),
        CGPoint(x: 250, y: 50),
        CGPoint(x: 280, y: 15),
        CGPoint(x: 310, y: 35),
        CGPoint(x: 340, y: 25),
        CGPoint(x: -15, y: 100),
        CGPoint(x: 40, y: 80),
        CGPoint(x: 100, y: 70),
        CGPoint(x: 160, y: 90),
        CGPoint(x: 220, y: 65),
        CGPoint(x: 280, y: 85)
    ]
    
    var body: some View {
        Group {
            if shouldShowMainApp {
                PresentationAnalyzerView()
                    .transition(.opacity)
            } else {
                splashScreen
            }
        }
        .animation(.easeOut(duration: 0.5), value: shouldShowMainApp)
    }
    
    private var splashScreen: some View {
        ZStack {
            // Background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Shooting Stars Layer
            GeometryReader { geometry in
                ForEach(0..<starPositions.count, id: \.self) { index in
                    ShootingStar(startPoint: starPositions[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1)
            
            // Character Container
            ZStack {
                // Enhanced glow effect
                Circle()
                    .fill(Color(red: 0.8, green: 1.0, blue: 0.8))
                    .frame(width: UIScreen.main.bounds.width * 1.7)
                    .blur(radius: 40)
                    .opacity(glowOpacity * 0.2)
                
                Circle()
                    .fill(Color(red: 0.8, green: 1.0, blue: 0.8))
                    .frame(width: UIScreen.main.bounds.width * 1.6)
                    .blur(radius: 30)
                    .opacity(glowOpacity * 0.3)
                
                // Main character
                Image("PEMO")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 1.8)
                    .colorMultiply(Color(red: 0.8, green: 1.0, blue: 0.8))
            }
            .frame(height: UIScreen.main.bounds.height)
            .offset(y: characterOffset)
            .zIndex(2)
            
            // Logo Container
            VStack {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.35)
                
                // Logo with glow
                ZStack {
                    // Glow effect for text
                    Text("PRZNT")
                        .font(.system(size: 55, weight: .heavy))
                        .foregroundColor(.white.opacity(0.5))
                        .blur(radius: 8)
                    
                    Text("PRZNT")
                        .font(.system(size: 55, weight: .heavy))
                        .foregroundColor(.white)
                }
                .opacity(isLogoVisible ? 1 : 0)
                
                Spacer()
            }
            .zIndex(3)
        }
        .onAppear(perform: startAnimations)
    }
    
    private func startAnimations() {
        // Start with character visible but below screen
        characterOffset = UIScreen.main.bounds.height
        
        // Animate logo fade in
        withAnimation(.easeOut(duration: logoAnimationDuration).delay(logoAnimationDelay)) {
            isLogoVisible = true
        }
        
        // Animate character sliding up and glow
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(characterAnimationDelay)) {
            characterOffset = UIScreen.main.bounds.height * 0.45
            glowOpacity = 1
        }
        
        // Transition to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDelay) {
            withAnimation {
                shouldShowMainApp = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
