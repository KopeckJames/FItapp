import Foundation
import SwiftUI
import HealthKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isBiometricEnabled = false
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    private let biometricEnabledKey = "biometricEnabled"
    private let biometricService = BiometricAuthService()
    
    init() {
        loadUser()
        loadBiometricPreference()
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Simple validation for demo
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            isLoading = false
            return
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email"
            isLoading = false
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Create user and save
        let user = User(email: email, name: extractNameFromEmail(email))
        currentUser = user
        isAuthenticated = true
        saveUser(user)
        
        // Request HealthKit authorization after successful login
        await requestHealthKitAccess()
        
        isLoading = false
    }
    
    func signUp(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Simple validation
        if name.isEmpty || email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            isLoading = false
            return
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email"
            isLoading = false
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Create user and save
        let user = User(email: email, name: name)
        currentUser = user
        isAuthenticated = true
        saveUser(user)
        
        // Request HealthKit authorization after successful signup
        await requestHealthKitAccess()
        
        isLoading = false
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: userKey)
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: userKey)
        }
    }
    
    private func loadUser() {
        if let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func extractNameFromEmail(_ email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first?.capitalized ?? "User"
    }
    
    // MARK: - Biometric Authentication
    
    func authenticateWithBiometrics() async -> Bool {
        guard isBiometricEnabled && biometricService.isBiometricAvailable else {
            return false
        }
        
        isLoading = true
        let result = await biometricService.authenticateWithBiometrics()
        isLoading = false
        
        switch result {
        case .success:
            if let data = userDefaults.data(forKey: userKey),
               let user = try? JSONDecoder().decode(User.self, from: data) {
                currentUser = user
                isAuthenticated = true
                return true
            }
            return false
        case .failure(let error):
            errorMessage = error
            return false
        }
    }
    
    func enableBiometricAuth() {
        isBiometricEnabled = true
        userDefaults.set(true, forKey: biometricEnabledKey)
    }
    
    func disableBiometricAuth() {
        isBiometricEnabled = false
        userDefaults.set(false, forKey: biometricEnabledKey)
    }
    
    func getBiometricService() -> BiometricAuthService {
        return biometricService
    }
    
    private func loadBiometricPreference() {
        isBiometricEnabled = userDefaults.bool(forKey: biometricEnabledKey)
    }
    
    // MARK: - HealthKit Integration
    
    private func requestHealthKitAccess() async {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // For now, we'll create a simple HealthKit authorization request
        // In a full implementation, this would use the HealthKitManager
        let healthStore = HKHealthStore()
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            print("HealthKit authorization granted")
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }
}