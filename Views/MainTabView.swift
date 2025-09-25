import SwiftUI
import HealthKit

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CompleteMealAnalyzerView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("Meal AI")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(Color(red: 0.7, green: 0.9, blue: 0.3))
        .preferredColorScheme(.dark)
    }
}

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    
                    Text("Welcome to Diabfit!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let user = authViewModel.currentUser {
                        Text("Hello, \(user.name)!")
                            .font(.title2)
                            .foregroundColor(Color.gray.opacity(0.8))
                    }
                    
                    VStack(spacing: 15) {
                        NavigationLink(destination: GlucoseTrackingView()) {
                            FeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Track Glucose",
                                description: "Monitor your blood sugar levels"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: HealthView()) {
                            FeatureCard(
                                icon: "heart.fill",
                                title: "Health",
                                description: "Track your overall health metrics"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: ExerciseView()) {
                            FeatureCard(
                                icon: "figure.walk",
                                title: "Exercise Log",
                                description: "Record your fitness activities"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: MedicationTrackerView()) {
                            FeatureCard(
                                icon: "pills.fill",
                                title: "Medication Tracker",
                                description: "Track medications and adherence"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: MealPlanningView()) {
                            FeatureCard(
                                icon: "fork.knife",
                                title: "Meal Planning",
                                description: "Plan diabetes-friendly meals"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: CompleteMealAnalyzerView()) {
                            FeatureCard(
                                icon: "camera.viewfinder",
                                title: "AI Meal Analyzer",
                                description: "Analyze meals with AI for diabetes insights"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Diabfit")
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.gray.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
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
                                .foregroundColor(.white)
                            
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(Color.gray.opacity(0.8))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile options
                    VStack(spacing: 0) {
                        // Biometric authentication toggle
                        if authViewModel.getBiometricService().isBiometricAvailable {
                            BiometricToggleRow(authViewModel: authViewModel)
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                        
                        ProfileRow(icon: "bell", title: "Notifications", showChevron: true)
                        ProfileRow(icon: "lock", title: "Privacy & Security", showChevron: true)
                        ProfileRow(icon: "questionmark.circle", title: "Help & Support", showChevron: true)
                        ProfileRow(icon: "info.circle", title: "About", showChevron: true)
                    }
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Sign out button
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                .foregroundColor(.white)
            
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
        .background(Color.clear)
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
                .foregroundColor(.white)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.gray.opacity(0.6))
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.clear)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}