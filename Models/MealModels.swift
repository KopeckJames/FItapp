import Foundation

// MARK: - Meal Data Models

struct Meal: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: MealType
    let carbs: Double
    let protein: Double
    let fat: Double
    let calories: Int
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let timestamp: Date
    let notes: String?
    let ingredients: [Ingredient]
    let recipe: Recipe?
    let glucoseImpact: GlucoseImpact?
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        
        var icon: String {
            switch self {
            case .breakfast: return "sun.max.fill"
            case .lunch: return "sun.min.fill"
            case .dinner: return "moon.fill"
            case .snack: return "leaf.fill"
            }
        }
        
        var color: String {
            switch self {
            case .breakfast: return "orange"
            case .lunch: return "blue"
            case .dinner: return "purple"
            case .snack: return "green"
            }
        }
    }
}

struct Ingredient: Identifiable, Codable {
    let id = UUID()
    let name: String
    let amount: Double
    let unit: String
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double
    let category: IngredientCategory
    
    enum IngredientCategory: String, CaseIterable, Codable {
        case protein = "Protein"
        case vegetables = "Vegetables"
        case fruits = "Fruits"
        case grains = "Grains"
        case dairy = "Dairy"
        case fats = "Fats & Oils"
        case spices = "Spices & Herbs"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .protein: return "flame.fill"
            case .vegetables: return "leaf.fill"
            case .fruits: return "apple.logo"
            case .grains: return "grain.fill"
            case .dairy: return "drop.fill"
            case .fats: return "drop.circle.fill"
            case .spices: return "sparkles"
            case .other: return "circle.fill"
            }
        }
    }
}

struct Recipe: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let instructions: [String]
    let prepTime: Int // minutes
    let cookTime: Int // minutes
    let servings: Int
    let difficulty: Difficulty
    let tags: [String]
    let diabeticFriendly: Bool
    let glycemicIndex: GlycemicIndex
    
    enum Difficulty: String, CaseIterable, Codable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }
    
    enum GlycemicIndex: String, CaseIterable, Codable {
        case low = "Low (≤55)"
        case medium = "Medium (56-69)"
        case high = "High (≥70)"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "red"
            }
        }
    }
}

struct GlucoseImpact: Codable {
    let predictedSpike: Double
    let timeToSpike: Int // minutes
    let duration: Int // minutes
    let confidence: Double
    let factors: [String]
}

// MARK: - Meal Planning Models

struct MealPlan: Identifiable, Codable {
    let id = UUID()
    let name: String
    let startDate: Date
    let endDate: Date
    let meals: [MealPlanEntry]
    let totalCalories: Int
    let totalCarbs: Double
    let totalProtein: Double
    let totalFat: Double
    let createdAt: Date
    let aiGenerated: Bool
}

struct MealPlanEntry: Identifiable, Codable {
    let id = UUID()
    let meal: Meal
    let scheduledDate: Date
    let scheduledTime: Date
    let completed: Bool
    let actualEatenTime: Date?
    let notes: String?
}

// MARK: - Grocery List Models

struct GroceryList: Identifiable, Codable {
    let id = UUID()
    let name: String
    let items: [GroceryItem]
    let createdAt: Date
    let updatedAt: Date
    let mealPlanId: UUID?
    let totalEstimatedCost: Double
}

struct GroceryItem: Identifiable, Codable {
    let id = UUID()
    let ingredient: Ingredient
    let quantity: Double
    let unit: String
    let purchased: Bool
    let estimatedCost: Double
    let store: String?
    let aisle: String?
    let priority: Priority
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case essential = "Essential"
        
        var color: String {
            switch self {
            case .low: return "gray"
            case .medium: return "blue"
            case .high: return "orange"
            case .essential: return "red"
            }
        }
    }
}

// MARK: - AI Analytics Models

struct MealAnalysis: Identifiable, Codable {
    let id = UUID()
    let mealId: UUID
    let analysisDate: Date
    let nutritionalScore: Double // 0-100
    let diabeticFriendliness: Double // 0-100
    let recommendations: [AIRecommendation]
    let improvements: [String]
    let alternatives: [Meal]
    let glucoseImpactPrediction: GlucoseImpact
}

struct AIRecommendation: Identifiable, Codable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Priority
    let actionable: Bool
    let estimatedBenefit: String
    
    enum RecommendationType: String, CaseIterable, Codable {
        case nutrition = "Nutrition"
        case glucose = "Glucose Control"
        case timing = "Meal Timing"
        case portion = "Portion Size"
        case substitution = "Ingredient Substitution"
        case preparation = "Preparation Method"
    }
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
}

// MARK: - Nutrition Tracking Models

struct DailyNutrition: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let totalCalories: Int
    let totalCarbs: Double
    let totalProtein: Double
    let totalFat: Double
    let totalFiber: Double
    let totalSugar: Double
    let totalSodium: Double
    let meals: [Meal]
    let targets: NutritionTargets
    let analysis: DailyNutritionAnalysis
}

struct NutritionTargets: Codable {
    let calories: Int
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}

struct DailyNutritionAnalysis: Codable {
    let calorieBalance: Double // percentage of target
    let macroBalance: MacroBalance
    let recommendations: [String]
    let warnings: [String]
    let score: Double // 0-100
}

struct MacroBalance: Codable {
    let carbsPercentage: Double
    let proteinPercentage: Double
    let fatPercentage: Double
    let isBalanced: Bool
    let recommendations: [String]
}

// MARK: - Food Database Models

struct FoodItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let brand: String?
    let barcode: String?
    let category: Ingredient.IngredientCategory
    let nutritionPer100g: NutritionInfo
    let servingSizes: [ServingSize]
    let glycemicIndex: Int?
    let diabeticFriendly: Bool
    let commonAllergens: [String]
}

struct NutritionInfo: Codable {
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let potassium: Double
    let calcium: Double
    let iron: Double
    let vitaminC: Double
}

struct ServingSize: Codable {
    let name: String
    let amount: Double
    let unit: String
    let grams: Double
}