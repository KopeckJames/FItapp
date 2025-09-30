import Foundation
import CoreData

// Utility to check if james@kopicsatx.com user exists in the database
class DatabaseUserChecker {
    
    static func checkForUser() {
        let coreDataManager = CoreDataManager.shared
        
        print("🔍 Checking for user: james@kopicsatx.com")
        print("=" * 50)
        
        // Check for the specific user
        if let user = coreDataManager.findUser(byEmail: "james@kopicsatx.com") {
            print("✅ USER FOUND!")
            print("📧 Email: \(user.email ?? "N/A")")
            print("👤 Name: \(user.name ?? "N/A")")
            print("📅 Created: \(user.createdAt?.formatted() ?? "N/A")")
            print("🎂 Date of Birth: \(user.dateOfBirth?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")")
            
            // Check related data
            let glucoseReadings = user.glucoseReadings?.count ?? 0
            let mealAnalyses = user.mealAnalyses?.count ?? 0
            let exercises = user.exercises?.count ?? 0
            let healthMetrics = user.healthMetrics?.count ?? 0
            let meals = user.meals?.count ?? 0
            
            print("\n📊 Associated Data:")
            print("   • Glucose Readings: \(glucoseReadings)")
            print("   • Meal Analyses: \(mealAnalyses)")
            print("   • Exercises: \(exercises)")
            print("   • Health Metrics: \(healthMetrics)")
            print("   • Meals: \(meals)")
            
        } else {
            print("❌ USER NOT FOUND")
            print("The user james@kopicsatx.com does not exist in the database")
        }
        
        // Show all users in database for context
        print("\n" + "=" * 50)
        print("📋 ALL USERS IN DATABASE:")
        
        let allUsers = coreDataManager.getAllUsers()
        if allUsers.isEmpty {
            print("   No users found in database")
        } else {
            for (index, user) in allUsers.enumerated() {
                print("   \(index + 1). \(user.email ?? "No email") - \(user.name ?? "No name")")
            }
        }
        
        print("=" * 50)
    }
}

// Usage:
// DatabaseUserChecker.checkForUser()