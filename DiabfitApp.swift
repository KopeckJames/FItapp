import SwiftUI

@main
struct DiabfitApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    if authViewModel.isAuthenticated {
                        MainTabView()
                            .environmentObject(authViewModel)
                    } else {
                        // Show biometric auth if enabled and available, otherwise show login
                        if authViewModel.isBiometricEnabled && authViewModel.getBiometricService().isBiometricAvailable {
                            BiometricAuthView()
                                .environmentObject(authViewModel)
                        } else {
                            LoginView()
                                .environmentObject(authViewModel)
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                // Show splash for 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}