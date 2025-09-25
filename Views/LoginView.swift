import SwiftUI

struct LoginView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var name = ""
    
    var body: some View {
        NavigationView {
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
                
                ScrollView {
                    VStack(spacing: 30) {
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
                        .padding(.top, 40)
                        
                        // Form section
                        VStack(spacing: 20) {
                            if isSignUpMode {
                                CustomTextField(
                                    text: $name,
                                    placeholder: "Full Name",
                                    icon: "person"
                                )
                            }
                            
                            CustomTextField(
                                text: $email,
                                placeholder: "Email",
                                icon: "envelope"
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            
                            CustomTextField(
                                text: $password,
                                placeholder: "Password",
                                icon: "lock",
                                isSecure: true
                            )
                            
                            if !authViewModel.errorMessage.isEmpty {
                                Text(authViewModel.errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                            
                            // Action button
                            Button(action: {
                                Task {
                                    if isSignUpMode {
                                        await authViewModel.signUp(name: name, email: email, password: password)
                                        // Offer biometric setup after successful signup
                                        if authViewModel.isAuthenticated {
                                            await offerBiometricSetup()
                                        }
                                    } else {
                                        await authViewModel.signIn(email: email, password: password)
                                        // Offer biometric setup after successful login
                                        if authViewModel.isAuthenticated {
                                            await offerBiometricSetup()
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(isSignUpMode ? "Sign Up" : "Sign In")
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
                            
                            // Toggle mode button
                            Button(action: {
                                isSignUpMode.toggle()
                                authViewModel.errorMessage = ""
                            }) {
                                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func offerBiometricSetup() async {
        let biometricService = authViewModel.getBiometricService()
        
        // Only offer if biometric is available and not already enabled
        if biometricService.isBiometricAvailable && !authViewModel.isBiometricEnabled {
            // Small delay to let the user see they're logged in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // This would typically show an alert, but for simplicity we'll auto-enable
            // In a real app, you'd show an alert asking the user if they want to enable biometrics
            authViewModel.enableBiometricAuth()
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    LoginView()
}