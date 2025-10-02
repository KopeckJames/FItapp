import Foundation
import Supabase

class SupabaseUserService {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - User Profile Management
    
    /// Ensures user profile exists in Supabase after authentication
    func ensureUserProfileExists() async throws {
        guard let user = supabase.auth.currentUser else {
            throw SupabaseError.notAuthenticated
        }
        
        // First, check if profile already exists
        let existingProfile = try? await getUserProfile()
        if existingProfile != nil {
            print("✅ User profile already exists")
            return
        }
        
        // Create profile if it doesn't exist
        try await createUserProfile(for: user)
    }
    
    /// Creates a new user profile in Supabase
    private func createUserProfile(for user: User) async throws {
        let userProfile: [String: Any] = [
            "auth_user_id": user.id.uuidString,
            "email": user.email ?? "",
            "name": extractUserName(from: user),
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            try await supabase
                .from("users")
                .insert(userProfile)
                .execute()
            
            print("✅ Created user profile for: \(user.email ?? "unknown")")
            
            // Log user creation event
            await logUserEvent(type: "profile_created", data: [
                "email": user.email ?? "",
                "auth_user_id": user.id.uuidString
            ])
            
        } catch {
            print("❌ Failed to create user profile: \(error)")
            
            // Try to fix existing profile if creation failed
            try await fixExistingUserProfile(for: user)
        }
    }
    
    /// Fixes existing user profile by updating auth_user_id
    private func fixExistingUserProfile(for user: User) async throws {
        guard let email = user.email else {
            throw SupabaseError.invalidEmail
        }
        
        let updateData: [String: Any] = [
            "auth_user_id": user.id.uuidString,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        try await supabase
            .from("users")
            .update(updateData)
            .eq("email", value: email)
            .execute()
        
        print("✅ Fixed existing user profile for: \(email)")
    }
    
    /// Gets current user profile from Supabase
    func getUserProfile() async throws -> UserProfile? {
        guard let user = supabase.auth.currentUser else {
            throw SupabaseError.notAuthenticated
        }
        
        let response = try await supabase
            .from("users")
            .select("*")
            .eq("auth_user_id", value: user.id.uuidString)
            .single()
            .execute()
        
        return try JSONDecoder().decode(UserProfile.self, from: response.data)
    }
    
    /// Updates user profile
    func updateUserProfile(_ updates: [String: Any]) async throws {
        guard let user = supabase.auth.currentUser else {
            throw SupabaseError.notAuthenticated
        }
        
        var updateData = updates
        updateData["updated_at"] = ISO8601DateFormatter().string(from: Date())
        
        try await supabase
            .from("users")
            .update(updateData)
            .eq("auth_user_id", value: user.id.uuidString)
            .execute()
    }
    
    // MARK: - User Authentication Flow
    
    /// Complete signup flow with profile creation
    func signUpWithProfile(email: String, password: String, name: String? = nil) async throws -> User {
        // Sign up with Supabase Auth
        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: name.map { ["name": AnyJSON.string($0)] } ?? [:]
        )
        
        guard let user = authResponse.user else {
            throw SupabaseError.signUpFailed
        }
        
        // The trigger should create the profile automatically,
        // but let's ensure it exists
        try await ensureUserProfileExists()
        
        return user
    }
    
    /// Complete signin flow with profile verification
    func signInWithProfile(email: String, password: String) async throws -> User {
        // Sign in with Supabase Auth
        let authResponse = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        guard let user = authResponse.user else {
            throw SupabaseError.signInFailed
        }
        
        // Ensure profile exists and is properly linked
        try await ensureUserProfileExists()
        
        return user
    }
    
    // MARK: - Utility Methods
    
    private func extractUserName(from user: User) -> String {
        // Try to get name from user metadata
        if let metadata = user.userMetadata,
           let name = metadata["name"]?.stringValue {
            return name
        }
        
        if let metadata = user.userMetadata,
           let fullName = metadata["full_name"]?.stringValue {
            return fullName
        }
        
        // Fallback to email prefix
        if let email = user.email {
            return String(email.split(separator: "@").first ?? "User")
        }
        
        return "User"
    }
    
    private func logUserEvent(type: String, data: [String: Any]) async {
        do {
            let eventData: [String: Any] = [
                "event_type": type,
                "event_data": data,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabase
                .from("app_analytics")
                .insert(eventData)
                .execute()
        } catch {
            print("⚠️ Failed to log user event: \(error)")
        }
    }
}

// MARK: - Models

struct UserProfile: Codable {
    let id: UUID
    let authUserId: UUID
    let email: String
    let name: String?
    let dateOfBirth: Date?
    let gender: String?
    let height: Double?
    let weight: Double?
    let hasDiabetes: Bool
    let diabetesType: String?
    let diagnosisDate: Date?
    let createdAt: Date
    let updatedAt: Date
    let lastSyncedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case email
        case name
        case dateOfBirth = "date_of_birth"
        case gender
        case height
        case weight
        case hasDiabetes = "has_diabetes"
        case diabetesType = "diabetes_type"
        case diagnosisDate = "diagnosis_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastSyncedAt = "last_synced_at"
    }
}

// MARK: - Errors

enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case invalidEmail
    case signUpFailed
    case signInFailed
    case profileCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidEmail:
            return "Invalid email address"
        case .signUpFailed:
            return "Failed to sign up user"
        case .signInFailed:
            return "Failed to sign in user"
        case .profileCreationFailed:
            return "Failed to create user profile"
        }
    }
}