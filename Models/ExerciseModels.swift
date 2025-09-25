import Foundation
import SwiftUI

// MARK: - Exercise and Workout Models

struct Workout: Identifiable, Codable {
    let id: UUID
    let type: String
    let duration: Int // minutes
    let intensity: String
    let calories: Int
    let timestamp: Date
    let notes: String?
    
    var icon: String {
        switch type.lowercased() {
        case "walking": return "figure.walk"
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        case "strength training": return "dumbbell.fill"
        case "yoga": return "figure.yoga"
        case "dancing": return "figure.dance"
        case "hiking": return "figure.hiking"
        case "tennis": return "tennis.racket"
        case "basketball": return "basketball.fill"
        case "soccer": return "soccerball"
        default: return "figure.walk"
        }
    }
    
    var color: Color {
        switch intensity.lowercased() {
        case "light": return .green
        case "moderate": return .orange
        case "vigorous": return .red
        default: return .blue
        }
    }
    
    init(type: String, duration: Int, intensity: String, calories: Int, timestamp: Date = Date(), notes: String? = nil) {
        self.id = UUID()
        self.type = type
        self.duration = duration
        self.intensity = intensity
        self.calories = calories
        self.timestamp = timestamp
        self.notes = notes
    }
    
    init(from entity: ExerciseEntity) {
        self.id = UUID()
        self.type = entity.type ?? "Other"
        self.duration = Int(entity.duration)
        self.intensity = "Moderate" // Default since not stored in current entity
        self.calories = Int(entity.calories)
        self.timestamp = entity.timestamp ?? Date()
        self.notes = entity.notes
    }
    
    public init(type: String, duration: Int, intensity: String, calories: Int, timestamp: Date, notes: String? = nil) {
        self.type = type
        self.duration = duration
        self.intensity = intensity
        self.calories = calories
        self.timestamp = timestamp
        self.notes = notes
    }
}

// MARK: - Exercise Types and Categories

enum ExerciseType: String, CaseIterable, Codable {
    case walking = "Walking"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case strengthTraining = "Strength Training"
    case yoga = "Yoga"
    case dancing = "Dancing"
    case hiking = "Hiking"
    case tennis = "Tennis"
    case basketball = "Basketball"
    case soccer = "Soccer"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .strengthTraining: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .dancing: return "figure.dance"
        case .hiking: return "figure.hiking"
        case .tennis: return "tennis.racket"
        case .basketball: return "basketball.fill"
        case .soccer: return "soccerball"
        case .other: return "figure.walk"
        }
    }
    
    var category: ExerciseCategory {
        switch self {
        case .walking, .running, .hiking: return .cardio
        case .cycling, .swimming: return .cardio
        case .strengthTraining: return .strength
        case .yoga: return .flexibility
        case .dancing: return .cardio
        case .tennis, .basketball, .soccer: return .sports
        case .other: return .other
        }
    }
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case cardio = "Cardio"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case sports = "Sports"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .cardio: return .red
        case .strength: return .blue
        case .flexibility: return .green
        case .sports: return .orange
        case .other: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .flexibility: return "figure.yoga"
        case .sports: return "sportscourt.fill"
        case .other: return "figure.walk"
        }
    }
}

enum ExerciseIntensity: String, CaseIterable, Codable {
    case light = "Light"
    case moderate = "Moderate"
    case vigorous = "Vigorous"
    
    var color: Color {
        switch self {
        case .light: return .green
        case .moderate: return .orange
        case .vigorous: return .red
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Easy pace, can hold conversation"
        case .moderate: return "Somewhat hard, slightly breathless"
        case .vigorous: return "Hard pace, difficult to talk"
        }
    }
}

// MARK: - Exercise Goals and Tracking

struct ExerciseGoal: Identifiable, Codable {
    let id: UUID
    let type: GoalType
    let target: Double
    let current: Double
    let unit: String
    let period: TimePeriod
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var progressPercentage: Double {
        return progress * 100
    }
    
    init(type: GoalType, target: Double, current: Double = 0, unit: String, period: TimePeriod, startDate: Date = Date(), endDate: Date? = nil, isActive: Bool = true) {
        self.id = UUID()
        self.type = type
        self.target = target
        self.current = current
        self.unit = unit
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }
    
    enum GoalType: String, CaseIterable, Codable {
        case duration = "Duration"
        case frequency = "Frequency"
        case calories = "Calories"
        case distance = "Distance"
        
        var icon: String {
            switch self {
            case .duration: return "clock.fill"
            case .frequency: return "repeat"
            case .calories: return "flame.fill"
            case .distance: return "location.fill"
            }
        }
    }
    
    enum TimePeriod: String, CaseIterable, Codable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
}

// MARK: - Exercise Analytics

struct ExerciseAnalytics: Identifiable, Codable {
    let id: UUID
    let period: TimePeriod
    let totalWorkouts: Int
    let totalDuration: Int // minutes
    let totalCalories: Int
    let averageIntensity: String
    let mostFrequentType: String
    let trends: [ExerciseTrend]
    let achievements: [Achievement]
    
    enum TimePeriod: String, CaseIterable, Codable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    init(period: TimePeriod, totalWorkouts: Int, totalDuration: Int, totalCalories: Int, averageIntensity: String, mostFrequentType: String, trends: [ExerciseTrend] = [], achievements: [Achievement] = []) {
        self.id = UUID()
        self.period = period
        self.totalWorkouts = totalWorkouts
        self.totalDuration = totalDuration
        self.totalCalories = totalCalories
        self.averageIntensity = averageIntensity
        self.mostFrequentType = mostFrequentType
        self.trends = trends
        self.achievements = achievements
    }
}

struct ExerciseTrend: Identifiable, Codable {
    let id: UUID
    let metric: String
    let direction: ExerciseTrendDirection
    let changePercentage: Double
    let description: String
    
    init(metric: String, direction: ExerciseTrendDirection, changePercentage: Double, description: String) {
        self.id = UUID()
        self.metric = metric
        self.direction = direction
        self.changePercentage = changePercentage
        self.description = description
    }
    
    enum ExerciseTrendDirection: String, CaseIterable, Codable {
        case increasing = "Increasing"
        case stable = "Stable"
        case decreasing = "Decreasing"
        
        var color: Color {
            switch self {
            case .increasing: return .green
            case .stable: return .blue
            case .decreasing: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .increasing: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .decreasing: return "arrow.down.right"
            }
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date
    let category: AchievementCategory
    let rarity: Rarity
    
    enum AchievementCategory: String, CaseIterable, Codable {
        case consistency = "Consistency"
        case milestone = "Milestone"
        case improvement = "Improvement"
        case variety = "Variety"
    }
    
    enum Rarity: String, CaseIterable, Codable {
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .yellow
            }
        }
    }
    
    init(title: String, description: String, icon: String, unlockedAt: Date = Date(), category: AchievementCategory, rarity: Rarity) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.icon = icon
        self.unlockedAt = unlockedAt
        self.category = category
        self.rarity = rarity
    }
}