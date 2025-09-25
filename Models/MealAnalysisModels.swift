import Foundation
import UIKit

// MARK: - Meal Analysis Result Models

struct MealAnalysisResult: Codable, Identifiable {
    var id: UUID?
    var timestamp: Date?
    var apiVersion: String?
    var processingTime: Int?
    
    let mealIdentification: MealIdentification
    let nutritionalAnalysis: NutritionalAnalysis
    let diabeticAnalysis: DiabeticAnalysis
    let glp1Considerations: GLP1Considerations
    let healthScore: HealthScore
    let recommendations: Recommendations
    let warnings: [String]
    let confidence: Double
    let analysisNotes: String?
    
    init(mealIdentification: MealIdentification, nutritionalAnalysis: NutritionalAnalysis, diabeticAnalysis: DiabeticAnalysis, glp1Considerations: GLP1Considerations, healthScore: HealthScore, recommendations: Recommendations, warnings: [String], confidence: Double, analysisNotes: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.mealIdentification = mealIdentification
        self.nutritionalAnalysis = nutritionalAnalysis
        self.diabeticAnalysis = diabeticAnalysis
        self.glp1Considerations = glp1Considerations
        self.healthScore = healthScore
        self.recommendations = recommendations
        self.warnings = warnings
        self.confidence = confidence
        self.analysisNotes = analysisNotes
    }
}

struct MealIdentification: Codable {
    let primaryDishes: [String]
    let ingredients: [String]
    let cookingMethods: [String]
    let estimatedPortionSizes: [String: String]
    let preparationNotes: String?
}

struct NutritionalAnalysis: Codable {
    let totalCalories: Int
    let macronutrients: Macronutrients
    let micronutrients: Micronutrients
    let sugar: SugarBreakdown
    let cholesterol: String?
    let saturatedFat: String?
    let transFat: String?
}

struct Macronutrients: Codable {
    let carbohydrates: MacroDetail
    let protein: MacroDetail
    let fat: MacroDetail
    let fiber: FiberDetail
}

struct MacroDetail: Codable {
    let grams: Double
    let percentage: Double
}

struct FiberDetail: Codable {
    let grams: Double
}

struct Micronutrients: Codable {
    let sodium: String
    let potassium: String
    let calcium: String
    let iron: String
    let vitaminC: String
    let vitaminD: String?
    let magnesium: String?
}

struct SugarBreakdown: Codable {
    let total: String
    let added: String
    let natural: String
}

struct DiabeticAnalysis: Codable {
    let glycemicIndex: GlycemicValue
    let glycemicLoad: GlycemicValue
    let estimatedBloodSugarImpact: BloodSugarImpact
    let carbQuality: CarbQuality
    let insulinResponse: InsulinResponse?
}

struct InsulinResponse: Codable {
    let estimated: String
    let timing: String
    let factors: [String]
}

struct GlycemicValue: Codable {
    let value: Int
    let category: String
    let reasoning: String?
}

struct BloodSugarImpact: Codable {
    let peakTime: String
    let expectedRise: String
    let duration: String
    let factors: [String]?
}

struct CarbQuality: Codable {
    let complexCarbs: String
    let simpleCarbs: String
    let fiberRatio: String
    let netCarbs: String?
}

struct GLP1Considerations: Codable {
    let gastroparesis: GastroparesisRisk
    let satietyFactor: SatietyFactor
    let digestionTime: DigestionTime
    let nausea: NauseaRisk?
    let recommendations: [String]
}

struct NauseaRisk: Codable {
    let risk: String
    let factors: [String]
}

struct GastroparesisRisk: Codable {
    let risk: String
    let reasoning: String
    let recommendations: [String]?
}

struct SatietyFactor: Codable {
    let score: Int
    let reasoning: String
    let duration: String?
}

struct DigestionTime: Codable {
    let estimated: String
    let impact: String
    let considerations: [String]?
}

struct HealthScore: Codable {
    let overall: Double
    let diabeticFriendly: Double
    let glp1Compatible: Double
    let nutritionalDensity: Double?
    let reasoning: String
}

struct Recommendations: Codable {
    let portionAdjustments: [String]
    let timingAdvice: [String]
    let modifications: [String]
    let bloodSugarManagement: [String]
    let medicationTiming: [String]?
}

// MARK: - Camera and Photo Models

struct PhotoAnalysisSession: Identifiable {
    let id = UUID()
    let image: UIImage
    let timestamp: Date
    let analysis: MealAnalysisResult?
    let isAnalyzing: Bool
    
    init(image: UIImage) {
        self.image = image
        self.timestamp = Date()
        self.analysis = nil
        self.isAnalyzing = true
    }
}

enum CameraError: LocalizedError {
    case cameraUnavailable
    case photoCaptureFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .photoCaptureFailed:
            return "Failed to capture photo"
        case .permissionDenied:
            return "Camera permission denied"
        }
    }
}

// MARK: - Analysis History Models

struct AnalysisHistory: Codable {
    let sessions: [HistorySession]
    let totalAnalyses: Int
    let averageConfidence: Double
    let mostCommonIngredients: [String]
    let nutritionalTrends: NutritionalTrends
}

struct HistorySession: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let analysis: MealAnalysisResult
    let userRating: Int? // 1-5 stars
    let userNotes: String?
    let actualBloodSugarResponse: BloodSugarResponse?
}

struct BloodSugarResponse: Codable {
    let preMealGlucose: Int
    let postMealGlucose: Int
    let peakGlucose: Int
    let timeToSpike: Int // minutes
    let actualVsPredicted: Double // percentage accuracy
}

struct NutritionalTrends: Codable {
    let averageCalories: Double
    let averageCarbs: Double
    let averageProtein: Double
    let averageFat: Double
    let averageGlycemicIndex: Double
    let glp1CompatibilityScore: Double
}