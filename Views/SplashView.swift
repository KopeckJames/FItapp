import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background gradient matching the Diabfit brand
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.8),
                    Color(red: 0.1, green: 0.5, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Diabfit Logo Recreation
                VStack(spacing: 20) {
                    // Heart with pulse icon
                    ZStack {
                        // Heart shape
                        Image(systemName: "heart")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        // Pulse line
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                            .offset(y: -5)
                    }
                    
                    // App name
                    Text("diabfit")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeIn(duration: 0.8).delay(0.5), value: showContent)
                }
                
                // Loading indicator
                if showContent {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                showContent = true
            }
        }
    }
}

#Preview {
    SplashView()
}
