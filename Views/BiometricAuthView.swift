import SwiftUI

struct BiometricAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showPasswordLogin = false
    
    private var biometricService: BiometricAuthService {
        authViewModel.getBiometricService()
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.8),
                    Color(red: 0.1, green: 0.5, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo section
                VStack(spacing: 15) {
                    ZStack {
                        Image(systemName: "heart")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                        
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .offset(y: -3)
                    }
                    
                    Text("diabfit")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
                
                // Biometric authentication section
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Image(systemName: biometricService.getBiometricIcon())
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Use \(biometricService.getBiometricTypeString()) to sign in")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Biometric auth button
                    Button(action: {
                        Task {
                            await performBiometricAuth()
                        }
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: biometricService.getBiometricIcon())
                                    .font(.title3)
                                Text("Authenticate with \(biometricService.getBiometricTypeString())")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)
                    .padding(.horizontal, 30)
                    
                    // Error message
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 30)
                    }
                    
                    // Alternative login option
                    Button(action: {
                        showPasswordLogin = true
                    }) {
                        Text("Use Password Instead")
                            .foregroundColor(.white)
                            .font(.caption)
                            .underline()
                    }
                }
                
                Spacer()
            }
            .padding(.top, 60)
        }
        .sheet(isPresented: $showPasswordLogin) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .onAppear {
            // Auto-trigger biometric authentication when view appears
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // Small delay for better UX
                await performBiometricAuth()
            }
        }
    }
    
    private func performBiometricAuth() async {
        authViewModel.errorMessage = ""
        let success = await authViewModel.authenticateWithBiometrics()
        if !success && authViewModel.errorMessage.isEmpty {
            authViewModel.errorMessage = "Authentication failed. Please try again."
        }
    }
}

#Preview {
    BiometricAuthView()
        .environmentObject(AuthViewModel())
}