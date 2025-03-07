import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isShowingPresentation = false
    @State private var glowOpacity = 0.0
    @State private var starOpacities: [Double] = (0..<20).map { _ in 0.0 } // Increased number of stars
    
    // Correct green color
    private let pemoColor = Color(red: 183/255, green: 255/255, blue: 183/255)
    
    // Fixed star positions and sizes with better distribution
    private let stars: [(position: CGPoint, size: CGFloat, duration: Double, delay: Double, maxOpacity: Double)] = {
        var positions: [(CGPoint, CGFloat, Double, Double, Double)] = []
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Define regions for better star coverage
        let regions = [
            // Corner areas (2 stars each)
            (x: 0...screenWidth*0.2, y: 0...screenHeight*0.2),           // Top left
            (x: screenWidth*0.8...screenWidth, y: 0...screenHeight*0.2),  // Top right
            (x: 0...screenWidth*0.2, y: screenHeight*0.8...screenHeight), // Bottom left
            (x: screenWidth*0.8...screenWidth, y: screenHeight*0.8...screenHeight), // Bottom right
            
            // Side areas (3 stars each side)
            (x: 0...screenWidth*0.15, y: screenHeight*0.3...screenHeight*0.7),    // Left
            (x: screenWidth*0.85...screenWidth, y: screenHeight*0.3...screenHeight*0.7), // Right
            
            // Middle area (6 stars)
            (x: screenWidth*0.25...screenWidth*0.75, y: screenHeight*0.35...screenHeight*0.65)
        ]
        
        // Place stars in corners (2 each)
        for cornerRegion in regions[0...3] {
            for _ in 0..<2 {
                let x = CGFloat.random(in: cornerRegion.x)
                let y = CGFloat.random(in: cornerRegion.y)
                
                positions.append((
                    CGPoint(x: x, y: y),
                    CGFloat.random(in: 0.8...1.5), // Smaller corner stars
                    Double.random(in: 2.0...3.0),
                    Double.random(in: 0...1.0),
                    Double.random(in: 0.5...0.7)
                ))
            }
        }
        
        // Place stars on sides (3 each side)
        for sideRegion in [regions[4], regions[5]] {
            for _ in 0..<3 {
                let x = CGFloat.random(in: sideRegion.x)
                let y = CGFloat.random(in: sideRegion.y)
                
                positions.append((
                    CGPoint(x: x, y: y),
                    CGFloat.random(in: 1.0...1.8), // Medium side stars
                    Double.random(in: 1.8...2.8),
                    Double.random(in: 0...1.5),
                    Double.random(in: 0.6...0.8)
                ))
            }
        }
        
        // Place stars in middle
        for _ in 0..<6 {
            let x = CGFloat.random(in: regions[6].x)
            let y = CGFloat.random(in: regions[6].y)
            
            positions.append((
                CGPoint(x: x, y: y),
                CGFloat.random(in: 1.2...2.0), // Larger middle stars
                Double.random(in: 1.5...2.5),
                Double.random(in: 0...1.5),
                Double.random(in: 0.7...0.9)
            ))
        }
        
        return positions
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Fixed Stars with individual animations
                ForEach(0..<stars.count, id: \.self) { index in
                    let star = stars[index]
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .blur(radius: 0.2)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .blur(radius: 0.4)
                                .frame(width: star.size * 1.8, height: star.size * 1.8)
                        )
                        .opacity(starOpacities[index])
                        .position(star.position)
                }
                .onAppear {
                    // Animate each star independently
                    for index in stars.indices {
                        let star = stars[index]
                        // Initial animation to fade in
                        withAnimation(.easeIn(duration: 0.8).delay(star.delay)) {
                            starOpacities[index] = star.maxOpacity
                        }
                        
                        // Start the continuous pulsing animation after fade in
                        DispatchQueue.main.asyncAfter(deadline: .now() + star.delay + 0.8) {
                            withAnimation(
                                .easeInOut(duration: star.duration)
                                .repeatForever(autoreverses: true)
                            ) {
                                starOpacities[index] = star.maxOpacity * 0.3 // More dramatic pulsing
                            }
                        }
                    }
                }
                
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
                            .frame(height: geometry.size.height * 0.2)
                        
                        Text("Record Your\nPresentation ")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Record Yourself, Practice,\nand Get Instant Feedback on\nYour Body Language and\nOratory Skills")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 15)
                        
                        Spacer()
                            .frame(height: geometry.size.height * 0.1)
                        
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
                
                // Skip Button
                VStack {
                    HStack {
                        Button(action: {
                            isShowingPresentation = true
                        }) {
                            Text("Skip")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(pemoColor)
                        }
                        .padding(.top, 3)
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    Spacer()
                }
                
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
