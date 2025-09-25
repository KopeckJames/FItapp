import Foundation
import CoreML
#if canImport(CreateML)
import CreateML
#endif

class AnalyticsEngine: ObservableObject {
    static let shared = AnalyticsEngine()
    
    @Published var glucoseInsights: GlucoseInsights?
    @Published var healthRecommendations: [HealthRecommendation] = []
    @Published var riskAssessment: RiskAssessment?
    
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    // MARK: - Glucose Pattern Analysis
    
    func updateGlucosePatterns(for user: UserEntity) {
        Task {
            await analyzeGlucosePatterns(for: user)
        }
    }
    
    @MainActor
    private func analyzeGlucosePatterns(for user: UserEntity) async {
        let readings = coreDataManager.getGlucoseAnalyticsData(for: user, days: 30)
        
        guard !readings.isEmpty else { return }
        
        let insights = GlucoseInsights(
            averageLevel: calculateAverageGlucose(readings),
            timeInRange: calculateTimeInRange(readings),
            patterns: identifyGlucosePatterns(readings),
            predictions: await predictGlucoseTrends(readings)
        )
        
        self.glucoseInsights = insights
        generateGlucoseRecommendations(insights)
    }
    
    private func calculateAverageGlucose(_ readings: [GlucoseReadingEntity]) -> Double {
        let total = readings.reduce(0) { $0 + Double($1.level) }
        return total / Double(readings.count)
    }
    
    private func calculateTimeInRange(_ readings: [GlucoseReadingEntity]) -> TimeInRange {
        let totalReadings = readings.count
        let inRange = readings.filter { $0.level >= 70 && $0.level <= 180 }.count
        let below = readings.filter { $0.level < 70 }.count
        let above = readings.filter { $0.level > 180 }.count
        
        return TimeInRange(
            inRange: Double(inRange) / Double(totalReadings) * 100,
            belowRange: Double(below) / Double(totalReadings) * 100,
            aboveRange: Double(above) / Double(totalReadings) * 100
        )
    }
    
    private func identifyGlucosePatterns(_ readings: [GlucoseReadingEntity]) -> [GlucosePattern] {
        var patterns: [GlucosePattern] = []
        
        // Dawn phenomenon detection
        let morningReadings = readings.filter { reading in
            let hour = Calendar.current.component(.hour, from: reading.timestamp ?? Date())
            return hour >= 6 && hour <= 9
        }
        
        if morningReadings.count >= 5 {
            let avgMorning = morningReadings.reduce(0) { $0 + Double($1.level) } / Double(morningReadings.count)
            if avgMorning > 140 {
                patterns.append(GlucosePattern(
                    type: .dawnPhenomenon,
                    description: "Elevated morning glucose levels detected",
                    confidence: 0.8
                ))
            }
        }
        
        // Post-meal spikes
        let correlationData = coreDataManager.getCorrelationData(for: readings.first?.user ?? UserEntity(), days: 30)
        patterns.append(contentsOf: analyzePostMealSpikes(correlationData))
        
        return patterns
    }
    
    private func analyzePostMealSpikes(_ data: CorrelationData) -> [GlucosePattern] {
        var patterns: [GlucosePattern] = []
        
        for meal in data.meals {
            guard let mealTime = meal.timestamp else { continue }
            
            // Find glucose readings 1-3 hours after meal
            let postMealReadings = data.glucoseReadings.filter { reading in
                guard let readingTime = reading.timestamp else { return false }
                let timeDiff = readingTime.timeIntervalSince(mealTime)
                return timeDiff > 3600 && timeDiff < 10800 // 1-3 hours
            }
            
            if let maxReading = postMealReadings.max(by: { $0.level < $1.level }),
               maxReading.level > 180 {
                patterns.append(GlucosePattern(
                    type: .postMealSpike,
                    description: "High glucose spike after \(meal.name) (\(meal.carbs)g carbs)",
                    confidence: 0.7
                ))
            }
        }
        
        return patterns
    }
    
    private func predictGlucoseTrends(_ readings: [GlucoseReadingEntity]) async -> [GlucosePrediction] {
        // Simple trend analysis - in production, this would use ML models
        guard readings.count >= 10 else { return [] }
        
        let recentReadings = Array(readings.suffix(10))
        let trend = calculateTrend(recentReadings)
        
        var predictions: [GlucosePrediction] = []
        
        if trend > 5 {
            predictions.append(GlucosePrediction(
                timeframe: "Next 2 hours",
                predictedRange: "Rising trend detected",
                confidence: 0.6
            ))
        } else if trend < -5 {
            predictions.append(GlucosePrediction(
                timeframe: "Next 2 hours",
                predictedRange: "Declining trend detected",
                confidence: 0.6
            ))
        }
        
        return predictions
    }
    
    private func calculateTrend(_ readings: [GlucoseReadingEntity]) -> Double {
        guard readings.count >= 2 else { return 0 }
        
        let first = Double(readings.first?.level ?? 0)
        let last = Double(readings.last?.level ?? 0)
        
        return last - first
    }
    
    // MARK: - Health Pattern Analysis
    
    func updateHealthPatterns(for user: UserEntity) {
        Task {
            await analyzeHealthPatterns(for: user)
        }
    }
    
    @MainActor
    private func analyzeHealthPatterns(for user: UserEntity) async {
        let correlationData = coreDataManager.getCorrelationData(for: user, days: 30)
        
        // Analyze exercise impact on glucose
        let exerciseImpact = analyzeExerciseImpact(correlationData)
        
        // Generate health recommendations
        var recommendations: [HealthRecommendation] = []
        
        if exerciseImpact.improvesGlucose {
            recommendations.append(HealthRecommendation(
                category: .exercise,
                title: "Exercise Benefits Detected",
                description: "Your glucose levels improve by an average of \(Int(exerciseImpact.averageImprovement))mg/dL after exercise",
                priority: .high,
                actionable: true
            ))
        }
        
        // Analyze nutrition patterns
        let nutritionInsights = analyzeNutritionPatterns(correlationData)
        recommendations.append(contentsOf: nutritionInsights)
        
        self.healthRecommendations = recommendations
        
        // Update risk assessment
        self.riskAssessment = calculateRiskAssessment(correlationData)
    }
    
    private func analyzeExerciseImpact(_ data: CorrelationData) -> ExerciseImpact {
        var improvements: [Double] = []
        
        for exercise in data.exercises {
            guard let exerciseTime = exercise.timestamp else { continue }
            
            // Find glucose readings before and after exercise
            let beforeReadings = data.glucoseReadings.filter { reading in
                guard let readingTime = reading.timestamp else { return false }
                let timeDiff = exerciseTime.timeIntervalSince(readingTime)
                return timeDiff > 0 && timeDiff < 7200 // 2 hours before
            }
            
            let afterReadings = data.glucoseReadings.filter { reading in
                guard let readingTime = reading.timestamp else { return false }
                let timeDiff = readingTime.timeIntervalSince(exerciseTime)
                return timeDiff > 0 && timeDiff < 7200 // 2 hours after
            }
            
            if let beforeAvg = beforeReadings.isEmpty ? nil : beforeReadings.reduce(0, { $0 + Double($1.level) }) / Double(beforeReadings.count),
               let afterAvg = afterReadings.isEmpty ? nil : afterReadings.reduce(0, { $0 + Double($1.level) }) / Double(afterReadings.count) {
                improvements.append(beforeAvg - afterAvg)
            }
        }
        
        let averageImprovement = improvements.isEmpty ? 0 : improvements.reduce(0, +) / Double(improvements.count)
        
        return ExerciseImpact(
            improvesGlucose: averageImprovement > 0,
            averageImprovement: averageImprovement
        )
    }
    
    private func analyzeNutritionPatterns(_ data: CorrelationData) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Analyze carb impact
        let highCarbMeals = data.meals.filter { $0.carbs > 45 }
        if !highCarbMeals.isEmpty {
            recommendations.append(HealthRecommendation(
                category: .nutrition,
                title: "High Carb Meal Impact",
                description: "Consider reducing carbs in meals to \(Int(45))g or less for better glucose control",
                priority: .medium,
                actionable: true
            ))
        }
        
        return recommendations
    }
    
    func updateExercisePatterns(for user: UserEntity) {
        // Trigger comprehensive analysis when exercise data is updated
        updateHealthPatterns(for: user)
    }
    
    func updateNutritionPatterns(for user: UserEntity) {
        // Trigger comprehensive analysis when nutrition data is updated
        updateHealthPatterns(for: user)
    }
    
    private func calculateRiskAssessment(_ data: CorrelationData) -> RiskAssessment {
        var riskFactors: [String] = []
        var overallRisk: RiskLevel = .low
        
        // Analyze glucose variability
        let glucoseLevels = data.glucoseReadings.map { Double($0.level) }
        if !glucoseLevels.isEmpty {
            let avg = glucoseLevels.reduce(0, +) / Double(glucoseLevels.count)
            let variance = glucoseLevels.map { pow($0 - avg, 2) }.reduce(0, +) / Double(glucoseLevels.count)
            let standardDeviation = sqrt(variance)
            
            if standardDeviation > 50 {
                riskFactors.append("High glucose variability")
                overallRisk = .high
            } else if standardDeviation > 30 {
                riskFactors.append("Moderate glucose variability")
                overallRisk = .medium
            }
            
            if avg > 180 {
                riskFactors.append("Elevated average glucose")
                overallRisk = .high
            }
        }
        
        return RiskAssessment(
            overallRisk: overallRisk,
            riskFactors: riskFactors,
            recommendations: generateRiskRecommendations(riskFactors)
        )
    }
    
    private func generateRiskRecommendations(_ riskFactors: [String]) -> [String] {
        var recommendations: [String] = []
        
        for factor in riskFactors {
            switch factor {
            case "High glucose variability":
                recommendations.append("Focus on consistent meal timing and carb counting")
            case "Elevated average glucose":
                recommendations.append("Consult with your healthcare provider about medication adjustments")
            default:
                break
            }
        }
        
        return recommendations
    }
    
    private func generateGlucoseRecommendations(_ insights: GlucoseInsights) {
        var recommendations: [HealthRecommendation] = []
        
        if insights.timeInRange.inRange < 70 {
            recommendations.append(HealthRecommendation(
                category: .glucose,
                title: "Improve Time in Range",
                description: "Your time in range is \(Int(insights.timeInRange.inRange))%. Aim for 70% or higher.",
                priority: .high,
                actionable: true
            ))
        }
        
        if insights.averageLevel > 180 {
            recommendations.append(HealthRecommendation(
                category: .glucose,
                title: "High Average Glucose",
                description: "Your average glucose is \(Int(insights.averageLevel))mg/dL. Consider consulting your healthcare provider.",
                priority: .high,
                actionable: true
            ))
        }
        
        self.healthRecommendations.append(contentsOf: recommendations)
    }
}

// MARK: - Data Structures

struct GlucoseInsights {
    let averageLevel: Double
    let timeInRange: TimeInRange
    let patterns: [GlucosePattern]
    let predictions: [GlucosePrediction]
}

struct TimeInRange: Codable {
    let inRange: Double      // 70-180 mg/dL
    let belowRange: Double   // <70 mg/dL
    let aboveRange: Double   // >180 mg/dL
}

struct GlucosePattern {
    let type: PatternType
    let description: String
    let confidence: Double
    
    enum PatternType {
        case dawnPhenomenon
        case postMealSpike
        case exerciseResponse
        case stressResponse
    }
}

struct GlucosePrediction {
    let timeframe: String
    let predictedRange: String
    let confidence: Double
}

struct HealthRecommendation {
    let category: Category
    let title: String
    let description: String
    let priority: Priority
    let actionable: Bool
    
    enum Category {
        case glucose, exercise, nutrition, medication, lifestyle
    }
    
    enum Priority {
        case low, medium, high, critical
    }
}

struct RiskAssessment {
    let overallRisk: RiskLevel
    let riskFactors: [String]
    let recommendations: [String]
}

enum RiskLevel {
    case low, medium, high, critical
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

struct ExerciseImpact {
    let improvesGlucose: Bool
    let averageImprovement: Double
}