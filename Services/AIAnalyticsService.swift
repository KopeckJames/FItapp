import Foundation

class AIAnalyticsService: ObservableObject {
    static let shared = AIAnalyticsService()
    
    @Published var isAnalyzing = false
    @Published var analysisResults: [MealAnalysis] = []
    
    private init() {}
    
    // MARK: - Meal Analysis
    
    func analyzeMeal(_ meal: Meal) async -> MealAnalysis {
        isAnalyzing = true
        
        // Simulate AI processing delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let nutritionalScore = calculateNutritionalScore(meal)
        let diabeticFriendliness = calculateDiabeticFriendliness(meal)
        let recommendations = generateRecommendations(for: meal)
        let improvements = generateImprovements(for: meal)
        let alternatives = await generateAlternatives(for: meal)
        let glucoseImpact = predictGlucoseImpact(for: meal)
        
        let analysis = MealAnalysis(
            mealId: meal.id,
            analysisDate: Date(),
            nutritionalScore: nutritionalScore,
            diabeticFriendliness: diabeticFriendliness,
            recommendations: recommendations,
            improvements: improvements,
            alternatives: alternatives,
            glucoseImpactPrediction: glucoseImpact
        )
        
        analysisResults.append(analysis)
        isAnalyzing = false
        
        return analysis
    }
    
    // MARK: - Nutritional Scoring
    
    private func calculateNutritionalScore(_ meal: Meal) -> Double {
        var score: Double = 50 // Base score
        
        // Protein content (good)
        if meal.protein >= 20 {
            score += 15
        } else if meal.protein >= 10 {
            score += 10
        }
        
        // Fiber content (good)
        if meal.fiber >= 10 {
            score += 15
        } else if meal.fiber >= 5 {
            score += 10
        }
        
        // Carb content (moderate for diabetics)
        if meal.carbs <= 30 {
            score += 10
        } else if meal.carbs <= 45 {
            score += 5
        } else if meal.carbs > 60 {
            score -= 10
        }
        
        // Sugar content (lower is better)
        if meal.sugar <= 10 {
            score += 10
        } else if meal.sugar > 25 {
            score -= 15
        }
        
        // Sodium content (lower is better)
        if meal.sodium <= 600 {
            score += 5
        } else if meal.sodium > 1200 {
            score -= 10
        }
        
        // Ingredient variety
        let uniqueCategories = Set(meal.ingredients.map { $0.category }).count
        score += Double(uniqueCategories * 2)
        
        return max(0, min(100, score))
    }
    
    private func calculateDiabeticFriendliness(_ meal: Meal) -> Double {
        var score: Double = 50 // Base score
        
        // Low carb content
        if meal.carbs <= 20 {
            score += 20
        } else if meal.carbs <= 30 {
            score += 15
        } else if meal.carbs <= 45 {
            score += 10
        } else {
            score -= 15
        }
        
        // High fiber (slows glucose absorption)
        if meal.fiber >= 8 {
            score += 15
        } else if meal.fiber >= 5 {
            score += 10
        }
        
        // Protein content (helps with satiety and glucose control)
        if meal.protein >= 15 {
            score += 15
        } else if meal.protein >= 10 {
            score += 10
        }
        
        // Low sugar content
        if meal.sugar <= 5 {
            score += 15
        } else if meal.sugar <= 10 {
            score += 10
        } else if meal.sugar > 20 {
            score -= 20
        }
        
        // Healthy fats
        if meal.fat >= 5 && meal.fat <= 15 {
            score += 10
        }
        
        // Check for diabetes-friendly ingredients
        let diabeticFriendlyIngredients = meal.ingredients.filter { ingredient in
            isDiabeticFriendly(ingredient)
        }
        score += Double(diabeticFriendlyIngredients.count * 3)
        
        return max(0, min(100, score))
    }
    
    private func isDiabeticFriendly(_ ingredient: Ingredient) -> Bool {
        let diabeticFriendlyFoods = [
            "salmon", "chicken", "turkey", "eggs", "tofu",
            "spinach", "broccoli", "cauliflower", "asparagus", "kale",
            "avocado", "nuts", "seeds", "olive oil",
            "berries", "apple", "citrus",
            "quinoa", "brown rice", "oats"
        ]
        
        return diabeticFriendlyFoods.contains { 
            ingredient.name.lowercased().contains($0) 
        }
    }
    
    // MARK: - Recommendations Generation
    
    private func generateRecommendations(for meal: Meal) -> [AIRecommendation] {
        var recommendations: [AIRecommendation] = []
        
        // Carb recommendations
        if meal.carbs > 45 {
            recommendations.append(AIRecommendation(
                type: .nutrition,
                title: "Reduce Carbohydrates",
                description: "Consider reducing carbs to under 45g per meal for better glucose control",
                priority: .high,
                actionable: true,
                estimatedBenefit: "May reduce post-meal glucose spike by 20-30mg/dL"
            ))
        }
        
        // Fiber recommendations
        if meal.fiber < 5 {
            recommendations.append(AIRecommendation(
                type: .nutrition,
                title: "Add More Fiber",
                description: "Include more vegetables or whole grains to increase fiber content",
                priority: .medium,
                actionable: true,
                estimatedBenefit: "Fiber helps slow glucose absorption and improves satiety"
            ))
        }
        
        // Protein recommendations
        if meal.protein < 15 {
            recommendations.append(AIRecommendation(
                type: .nutrition,
                title: "Increase Protein",
                description: "Add lean protein to help with glucose control and satiety",
                priority: .medium,
                actionable: true,
                estimatedBenefit: "Protein helps stabilize blood sugar and reduces hunger"
            ))
        }
        
        // Timing recommendations
        if meal.type == .dinner && meal.carbs > 30 {
            recommendations.append(AIRecommendation(
                type: .timing,
                title: "Consider Earlier Dinner",
                description: "Eating dinner earlier may help with overnight glucose control",
                priority: .low,
                actionable: true,
                estimatedBenefit: "May improve morning glucose levels"
            ))
        }
        
        // Portion recommendations
        if meal.calories > 600 {
            recommendations.append(AIRecommendation(
                type: .portion,
                title: "Consider Smaller Portions",
                description: "Large meals can cause bigger glucose spikes",
                priority: .medium,
                actionable: true,
                estimatedBenefit: "Smaller portions lead to more stable glucose levels"
            ))
        }
        
        return recommendations
    }
    
    private func generateImprovements(for meal: Meal) -> [String] {
        var improvements: [String] = []
        
        if meal.carbs > 45 {
            improvements.append("Replace refined grains with whole grains or vegetables")
        }
        
        if meal.fiber < 5 {
            improvements.append("Add a side salad or steamed vegetables")
        }
        
        if meal.protein < 15 {
            improvements.append("Include lean protein like chicken, fish, or tofu")
        }
        
        if meal.sugar > 15 {
            improvements.append("Reduce added sugars and choose fresh fruits over dried")
        }
        
        if meal.sodium > 800 {
            improvements.append("Use herbs and spices instead of salt for flavoring")
        }
        
        let vegetableCount = meal.ingredients.filter { $0.category == .vegetables }.count
        if vegetableCount < 2 {
            improvements.append("Add more non-starchy vegetables for nutrients and fiber")
        }
        
        return improvements
    }
    
    private func generateAlternatives(for meal: Meal) async -> [Meal] {
        // Generate healthier alternatives to the current meal
        var alternatives: [Meal] = []
        
        // Lower carb alternative
        if meal.carbs > 30 {
            let lowCarbAlternative = createLowCarbAlternative(basedOn: meal)
            alternatives.append(lowCarbAlternative)
        }
        
        // Higher protein alternative
        if meal.protein < 20 {
            let highProteinAlternative = createHighProteinAlternative(basedOn: meal)
            alternatives.append(highProteinAlternative)
        }
        
        // Plant-based alternative
        let plantBasedAlternative = createPlantBasedAlternative(basedOn: meal)
        alternatives.append(plantBasedAlternative)
        
        return alternatives
    }
    
    private func createLowCarbAlternative(basedOn meal: Meal) -> Meal {
        // Create a lower carb version of the meal
        let newIngredients = meal.ingredients.map { ingredient in
            if ingredient.category == .grains {
                // Replace grains with vegetables
                return Ingredient(
                    name: "Cauliflower Rice",
                    amount: ingredient.amount,
                    unit: ingredient.unit,
                    calories: ingredient.calories * 0.3,
                    carbs: ingredient.carbs * 0.2,
                    protein: ingredient.protein,
                    fat: ingredient.fat,
                    fiber: ingredient.fiber * 1.5,
                    category: .vegetables
                )
            }
            return ingredient
        }
        
        let newNutrition = calculateTotalNutrition(from: newIngredients)
        
        return Meal(
            name: "\(meal.name) (Low Carb)",
            type: meal.type,
            carbs: newNutrition.carbs,
            protein: newNutrition.protein,
            fat: newNutrition.fat,
            calories: Int(newNutrition.calories),
            fiber: newNutrition.fiber,
            sugar: newNutrition.sugar,
            sodium: newNutrition.sodium,
            timestamp: meal.timestamp,
            notes: "Lower carb alternative",
            ingredients: newIngredients,
            recipe: meal.recipe,
            glucoseImpact: nil
        )
    }
    
    private func createHighProteinAlternative(basedOn meal: Meal) -> Meal {
        var newIngredients = meal.ingredients
        
        // Add protein source
        let proteinIngredient = Ingredient(
            name: "Greek Yogurt",
            amount: 100,
            unit: "g",
            calories: 100,
            carbs: 6,
            protein: 17,
            fat: 0,
            fiber: 0,
            category: .dairy
        )
        
        newIngredients.append(proteinIngredient)
        
        let newNutrition = calculateTotalNutrition(from: newIngredients)
        
        return Meal(
            name: "\(meal.name) (High Protein)",
            type: meal.type,
            carbs: newNutrition.carbs,
            protein: newNutrition.protein,
            fat: newNutrition.fat,
            calories: Int(newNutrition.calories),
            fiber: newNutrition.fiber,
            sugar: newNutrition.sugar,
            sodium: newNutrition.sodium,
            timestamp: meal.timestamp,
            notes: "Higher protein alternative",
            ingredients: newIngredients,
            recipe: meal.recipe,
            glucoseImpact: nil
        )
    }
    
    private func createPlantBasedAlternative(basedOn meal: Meal) -> Meal {
        let newIngredients = meal.ingredients.map { ingredient in
            if ingredient.category == .protein && ingredient.name.lowercased().contains("chicken") {
                return Ingredient(
                    name: "Tofu",
                    amount: ingredient.amount,
                    unit: ingredient.unit,
                    calories: ingredient.calories * 0.8,
                    carbs: ingredient.carbs + 2,
                    protein: ingredient.protein * 0.9,
                    fat: ingredient.fat * 1.2,
                    fiber: ingredient.fiber + 1,
                    category: .protein
                )
            }
            return ingredient
        }
        
        let newNutrition = calculateTotalNutrition(from: newIngredients)
        
        return Meal(
            name: "\(meal.name) (Plant-Based)",
            type: meal.type,
            carbs: newNutrition.carbs,
            protein: newNutrition.protein,
            fat: newNutrition.fat,
            calories: Int(newNutrition.calories),
            fiber: newNutrition.fiber,
            sugar: newNutrition.sugar,
            sodium: newNutrition.sodium,
            timestamp: meal.timestamp,
            notes: "Plant-based alternative",
            ingredients: newIngredients,
            recipe: meal.recipe,
            glucoseImpact: nil
        )
    }
    
    // MARK: - Glucose Impact Prediction
    
    private func predictGlucoseImpact(for meal: Meal) -> GlucoseImpact {
        // Advanced AI model for glucose impact prediction
        let carbLoad = meal.carbs
        let fiberEffect = meal.fiber * 0.6 // Fiber reduces glucose impact
        let proteinEffect = meal.protein * 0.15 // Protein slows absorption
        let fatEffect = meal.fat * 0.1 // Fat slows absorption
        
        let netCarbImpact = max(0, carbLoad - fiberEffect - proteinEffect - fatEffect)
        
        // Predict glucose spike based on net carb impact
        let predictedSpike = netCarbImpact * 2.8 // mg/dL per net carb gram
        
        // Time to peak depends on meal composition
        let timeToSpike = calculateTimeToSpike(meal: meal)
        
        // Duration depends on meal size and composition
        let duration = calculateSpikeDuration(meal: meal)
        
        // Confidence based on data quality and meal complexity
        let confidence = calculatePredictionConfidence(meal: meal)
        
        let factors = identifyGlucoseFactors(meal: meal)
        
        return GlucoseImpact(
            predictedSpike: predictedSpike,
            timeToSpike: timeToSpike,
            duration: duration,
            confidence: confidence,
            factors: factors
        )
    }
    
    private func calculateTimeToSpike(meal: Meal) -> Int {
        var baseTime = 60 // minutes
        
        // Fiber slows absorption
        if meal.fiber > 5 {
            baseTime += 15
        }
        
        // Fat slows absorption
        if meal.fat > 10 {
            baseTime += 10
        }
        
        // Protein slows absorption
        if meal.protein > 15 {
            baseTime += 10
        }
        
        // Liquid vs solid affects absorption speed
        let hasLiquids = meal.ingredients.contains { $0.name.lowercased().contains("juice") || $0.name.lowercased().contains("smoothie") }
        if hasLiquids {
            baseTime -= 15
        }
        
        return max(30, min(120, baseTime))
    }
    
    private func calculateSpikeDuration(meal: Meal) -> Int {
        var baseDuration = 120 // minutes
        
        // Higher carb meals have longer duration
        if meal.carbs > 45 {
            baseDuration += 30
        }
        
        // Fat extends duration
        if meal.fat > 15 {
            baseDuration += 20
        }
        
        // Fiber helps with glucose clearance
        if meal.fiber > 8 {
            baseDuration -= 15
        }
        
        return max(90, min(180, baseDuration))
    }
    
    private func calculatePredictionConfidence(meal: Meal) -> Double {
        var confidence = 0.7 // Base confidence
        
        // More ingredients = more complexity = lower confidence
        if meal.ingredients.count <= 5 {
            confidence += 0.1
        } else if meal.ingredients.count > 10 {
            confidence -= 0.1
        }
        
        // Known ingredients increase confidence
        let knownIngredients = meal.ingredients.filter { isDiabeticFriendly($0) }
        confidence += Double(knownIngredients.count) * 0.02
        
        // Balanced meals are more predictable
        let carbRatio = meal.carbs / Double(meal.calories) * 100
        if carbRatio >= 40 && carbRatio <= 60 {
            confidence += 0.05
        }
        
        return max(0.3, min(0.95, confidence))
    }
    
    private func identifyGlucoseFactors(meal: Meal) -> [String] {
        var factors: [String] = []
        
        if meal.carbs > 30 {
            factors.append("High carbohydrate content")
        }
        
        if meal.fiber > 5 {
            factors.append("High fiber content (reduces spike)")
        }
        
        if meal.protein > 15 {
            factors.append("High protein content (slows absorption)")
        }
        
        if meal.fat > 10 {
            factors.append("Fat content (slows absorption)")
        }
        
        if meal.sugar > 10 {
            factors.append("Added sugars (faster absorption)")
        }
        
        let hasRefinedCarbs = meal.ingredients.contains { 
            $0.name.lowercased().contains("white") || 
            $0.name.lowercased().contains("refined") 
        }
        if hasRefinedCarbs {
            factors.append("Refined carbohydrates (faster absorption)")
        }
        
        return factors
    }
    
    // MARK: - Personalized Recommendations
    
    func generatePersonalizedRecommendations(user: User, mealHistory: [Meal]) async -> [AIRecommendation] {
        var recommendations: [AIRecommendation] = []
        
        // Analyze eating patterns
        let patterns = analyzeMealPatterns(mealHistory)
        
        // Generate recommendations based on patterns
        if patterns.averageCarbs > 50 {
            recommendations.append(AIRecommendation(
                type: .nutrition,
                title: "Reduce Daily Carb Intake",
                description: "Your average carb intake is \(Int(patterns.averageCarbs))g per meal. Consider reducing to 30-45g.",
                priority: .high,
                actionable: true,
                estimatedBenefit: "Could improve overall glucose control"
            ))
        }
        
        if patterns.fiberIntake < 25 {
            recommendations.append(AIRecommendation(
                type: .nutrition,
                title: "Increase Daily Fiber",
                description: "Aim for 25-35g of fiber daily to help with glucose control.",
                priority: .medium,
                actionable: true,
                estimatedBenefit: "Better glucose stability and digestive health"
            ))
        }
        
        if patterns.irregularMealTiming {
            recommendations.append(AIRecommendation(
                type: .timing,
                title: "Establish Regular Meal Times",
                description: "Consistent meal timing helps with glucose predictability.",
                priority: .medium,
                actionable: true,
                estimatedBenefit: "More stable glucose patterns throughout the day"
            ))
        }
        
        return recommendations
    }
    
    private func analyzeMealPatterns(_ meals: [Meal]) -> MealPatterns {
        let recentMeals = Array(meals.suffix(30)) // Last 30 meals
        
        let averageCarbs = recentMeals.reduce(0) { $0 + $1.carbs } / Double(recentMeals.count)
        let averageProtein = recentMeals.reduce(0) { $0 + $1.protein } / Double(recentMeals.count)
        let fiberIntake = recentMeals.reduce(0) { $0 + $1.fiber }
        
        // Check meal timing regularity
        let mealTimes = recentMeals.map { Calendar.current.component(.hour, from: $0.timestamp) }
        let timeVariance = calculateVariance(mealTimes.map { Double($0) })
        let irregularMealTiming = timeVariance > 2.0
        
        return MealPatterns(
            averageCarbs: averageCarbs,
            averageProtein: averageProtein,
            fiberIntake: fiberIntake,
            irregularMealTiming: irregularMealTiming
        )
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    // MARK: - Helper Methods
    
    private func calculateTotalNutrition(from ingredients: [Ingredient]) -> NutritionInfo {
        return NutritionInfo(
            calories: ingredients.reduce(0) { $0 + $1.calories },
            carbs: ingredients.reduce(0) { $0 + $1.carbs },
            protein: ingredients.reduce(0) { $0 + $1.protein },
            fat: ingredients.reduce(0) { $0 + $1.fat },
            fiber: ingredients.reduce(0) { $0 + $1.fiber },
            sugar: 0, // Simplified
            sodium: 0, // Simplified
            potassium: 0,
            calcium: 0,
            iron: 0,
            vitaminC: 0
        )
    }
}

// MARK: - Supporting Types

struct MealPatterns {
    let averageCarbs: Double
    let averageProtein: Double
    let fiberIntake: Double
    let irregularMealTiming: Bool
}