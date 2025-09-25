import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(Color(red: 0.7, green: 0.9, blue: 0.3))
    }
}

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                
                Text("Welcome to Diabfit!")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let user = authViewModel.currentUser {
                    Text("Hello, \(user.name)!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 15) {
                    FeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Glucose",
                        description: "Monitor your blood sugar levels"
                    )
                    
                    FeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Health",
                        description: "Monitor your blood sugar levels"
                    )
                    FeatureCard(
                        icon: "figure.walk",
                        title: "Exercise Log",
                        description: "Record your fitness activities"
                    )
                    
                    FeatureCard(
                        icon: "fork.knife",
                        title: "Meal Planning",
                        description: "Plan diabetes-friendly meals"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Diabfit")
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile header
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    
                    if let user = authViewModel.currentUser {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Profile options
                VStack(spacing: 0) {
                    // Biometric authentication toggle
                    if authViewModel.getBiometricService().isBiometricAvailable {
                        BiometricToggleRow(authViewModel: authViewModel)
                        Divider()
                    }
                    
                    ProfileRow(icon: "bell", title: "Notifications", showChevron: true)
                    ProfileRow(icon: "lock", title: "Privacy & Security", showChevron: true)
                    ProfileRow(icon: "questionmark.circle", title: "Help & Support", showChevron: true)
                    ProfileRow(icon: "info.circle", title: "About", showChevron: true)
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Sign out button
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
        }
    }
}

struct BiometricToggleRow: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        HStack {
            Image(systemName: authViewModel.getBiometricService().getBiometricIcon())
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                .frame(width: 25)
            
            Text(authViewModel.getBiometricService().getBiometricTypeString())
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { authViewModel.isBiometricEnabled },
                set: { enabled in
                    if enabled {
                        Task {
                            let result = await authViewModel.getBiometricService().authenticateWithBiometrics()
                            await MainActor.run {
                                switch result {
                                case .success:
                                    authViewModel.enableBiometricAuth()
                                case .failure:
                                    // Keep toggle off if authentication failed
                                    break
                                }
                            }
                        }
                    } else {
                        authViewModel.disableBiometricAuth()
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let showChevron: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                .frame(width: 25)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}