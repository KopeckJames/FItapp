import Foundation
import Combine
import SwiftUI

@MainActor
class MealPlanningService: ObservableObject {
    @Published var breakfastMeals: [PlannedMeal] = []
    @Published var lunchMeals: [PlannedMeal] = []
    @Published var dinnerMeals: [PlannedMeal] = []
    @Published var snackMeals: [PlannedMeal] = []
    @Published var recommendedMeals: [RecommendedMeal] = []
    
    @Published var dailyCarbs: Double = 0
    @Published var dailyProtein: Double = 0
    @Published var dailyCalories: Double = 0
    @Published var predictedGlucoseImpact: Int = 0
    
    // Daily targets (can be customized based on user profile)
    @Published var carbsTarget: Double = 150 // grams
    @Published var proteinTarget: Double = 80 // grams
    @Published var caloriesTarget: Double = 1800 // calories
    
    @Published var isLoading = false
    @Published var error: MealPlanningError?
    
    private let coreDataManager = CoreDataManager.shared
    private var currentUser: UserEntity?
    private var currentDate = Date()
    
    init() {
        self.currentUser = coreDataManager.getCurrentUser()
        loadRecommendedMeals()
    }
    
    // MARK: - Meal Management
    
    func loadMealsForDate(_ date: Date) {
        currentDate = date
        
        guard let user = currentUser else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let request = NSFetchRequest<MealEntity>(entityName: "MealEntity")
        request.predicate = NSPredicate(
            format: "user == %@ AND timestamp >= %@ AND timestamp < %@",
            user, startOfDay as NSDate, endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealEntity.timestamp, ascending: true)]
        
        do {
            let entities = try coreDataManager.context.fetch(request)
            let meals = entities.compactMap { PlannedMeal(from: $0) }
            
            // Categorize meals by type
            breakfastMeals = meals.filter { $0.type == .breakfast }
            lunchMeals = meals.filter { $0.type == .lunch }
            dinnerMeals = meals.filter { $0.type == .dinner }
            snackMeals = meals.filter { $0.type == .snack }
            
            calculateDailyNutrition()
            
        } catch {
            self.error = .dataLoadFailed(error.localizedDescription)
        }
    }
    
    func addMealToPlan(_ meal: PlannedMeal, for date: Date) {
        guard let user = currentUser else { return }
        
        // Save to Core Data
        coreDataManager.saveMeal(
            name: meal.name,
            mealType: meal.type.rawValue,
            carbs: meal.carbs,
            protein: meal.protein,
            calories: meal.calories,
            timestamp: meal.scheduledTime,
            notes: meal.notes,
            for: user
        )
        
        // Reload meals for the date
        loadMealsForDate(date)
    }
    
    func addMealToPlan(_ recommendedMeal: RecommendedMeal, for date: Date) {
        let plannedMeal = PlannedMeal(
            name: recommendedMeal.name,
            type: .lunch, // Default to lunch, user can change
            carbs: recommendedMeal.carbs,
            protein: recommendedMeal.protein,
            calories: recommendedMeal.calories,
            notes: recommendedMeal.description,
            scheduledTime: date
        )
        
        addMealToPlan(plannedMeal, for: date)
    }
    
    func deleteMeal(_ meal: PlannedMeal) {
        // Implementation for deleting meals
        loadMealsForDate(currentDate)
    }
    
    // MARK: - Nutrition Calculations
    
    private func calculateDailyNutrition() {
        let allMeals = breakfastMeals + lunchMeals + dinnerMeals + snackMeals
        
        dailyCarbs = allMeals.reduce(0) { $0 + $1.carbs }
        dailyProtein = allMeals.reduce(0) { $0 + $1.protein }
        dailyCalories = Double(allMeals.reduce(0) { $0 + $1.calories })
        
        // Calculate predicted glucose impact
        predictedGlucoseImpact = calculateGlucoseImpact(from: allMeals)
    }
    
    private func calculateGlucoseImpact(from meals: [PlannedMeal]) -> Int {
        // Simplified glucose impact calculation
        // In a real app, this would use more sophisticated algorithms
        let totalCarbs = meals.reduce(0) { $0 + $1.carbs }
        let carbImpact = totalCarbs * 3 // Rough estimate: 1g carbs = ~3 mg/dL glucose rise
        
        // Factor in meal timing and combinations
        let timingFactor = meals.count > 3 ? 0.8 : 1.0 // Better distribution = lower impact
        
        return Int(carbImpact * timingFactor)
    }
    
    // MARK: - Meal Recommendations
    
    private func loadRecommendedMeals() {
        // In a real app, this would fetch from a database or API
        recommendedMeals = [
            RecommendedMeal(
                name: "Grilled Chicken Salad",
                description: "Mixed greens with grilled chicken, avocado, and olive oil dressing",
                carbs: 15,
                protein: 35,
                calories: 320,
                diabetesFriendly: true,
                glycemicIndex: .low,
                imageURL: nil
            ),
            RecommendedMeal(
                name: "Quinoa Bowl",
                description: "Quinoa with roasted vegetables and tahini dressing",
                carbs: 45,
                protein: 12,
                calories: 380,
                diabetesFriendly: true,
                glycemicIndex: .medium,
                imageURL: nil
            ),
            RecommendedMeal(
                name: "Salmon with Broccoli",
                description: "Baked salmon with steamed broccoli and brown rice",
                carbs: 30,
                protein: 40,
                calories: 420,
                diabetesFriendly: true,
                glycemicIndex: .low,
                imageURL: nil
            ),
            RecommendedMeal(
                name: "Greek Yogurt Parfait",
                description: "Plain Greek yogurt with berries and nuts",
                carbs: 20,
                protein: 15,
                calories: 180,
                diabetesFriendly: true,
                glycemicIndex: .low,
                imageURL: nil
            ),
            RecommendedMeal(
                name: "Vegetable Stir-Fry",
                description: "Mixed vegetables with tofu in a light sauce",
                carbs: 25,
                protein: 18,
                calories: 280,
                diabetesFriendly: true,
                glycemicIndex: .low,
                imageURL: nil
            ),
            RecommendedMeal(
                name: "Turkey and Avocado Wrap",
                description: "Whole wheat wrap with turkey, avocado, and vegetables",
                carbs: 35,
                protein: 25,
                calories: 350,
                diabetesFriendly: true,
                glycemicIndex: .medium,
                imageURL: nil
            ),
            RecommendedMeal(
                name: "Lentil Soup",
                description: "Hearty lentil soup with vegetables and herbs",
                carbs: 40,
                protein: 20,
                calories: 300,
                diabetesFriendly: true,
                glycemicIndex: .medium,
                imageURL: nil
            ),
            RecommendedMeal(
                name: "Egg and Vegetable Scramble",
                description: "Scrambled eggs with spinach, tomatoes, and peppers",
                carbs: 8,
                protein: 20,
                calories: 220,
                diabetesFriendly: true,
                glycemicIndex: .low,
                imageURL: nil
            )
        ]
    }
    
    func getMealSuggestions(for mealType: MealType, targetCarbs: Double? = nil) -> [RecommendedMeal] {
        var suggestions = recommendedMeals
        
        // Filter by carb content if specified
        if let targetCarbs = targetCarbs {
            suggestions = suggestions.filter { abs($0.carbs - targetCarbs) <= 10 }
        }
        
        // Sort by diabetes-friendliness and glycemic index
        suggestions.sort { meal1, meal2 in
            if meal1.diabetesFriendly != meal2.diabetesFriendly {
                return meal1.diabetesFriendly && !meal2.diabetesFriendly
            }
            return meal1.glycemicIndex.rawValue < meal2.glycemicIndex.rawValue
        }
        
        return Array(suggestions.prefix(5))
    }
    
    // MARK: - Meal Planning Intelligence
    
    func generateWeeklyMealPlan() -> [Date: [PlannedMeal]] {
        var weeklyPlan: [Date: [PlannedMeal]] = [:]
        let calendar = Calendar.current
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: Date()) else { continue }
            
            let dailyMeals = generateDailyMealPlan(for: date)
            weeklyPlan[date] = dailyMeals
        }
        
        return weeklyPlan
    }
    
    private func generateDailyMealPlan(for date: Date) -> [PlannedMeal] {
        let targetCarbsPerMeal = carbsTarget / 4 // Distribute across 3 meals + 1 snack
        
        var dailyMeals: [PlannedMeal] = []
        
        // Breakfast
        if let breakfastSuggestion = getMealSuggestions(for: .breakfast, targetCarbs: targetCarbsPerMeal).first {
            let breakfast = PlannedMeal(
                name: breakfastSuggestion.name,
                type: .breakfast,
                carbs: breakfastSuggestion.carbs,
                protein: breakfastSuggestion.protein,
                calories: breakfastSuggestion.calories,
                notes: breakfastSuggestion.description,
                scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
            )
            dailyMeals.append(breakfast)
        }
        
        // Lunch
        if let lunchSuggestion = getMealSuggestions(for: .lunch, targetCarbs: targetCarbsPerMeal).first {
            let lunch = PlannedMeal(
                name: lunchSuggestion.name,
                type: .lunch,
                carbs: lunchSuggestion.carbs,
                protein: lunchSuggestion.protein,
                calories: lunchSuggestion.calories,
                notes: lunchSuggestion.description,
                scheduledTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date) ?? date
            )
            dailyMeals.append(lunch)
        }
        
        // Dinner
        if let dinnerSuggestion = getMealSuggestions(for: .dinner, targetCarbs: targetCarbsPerMeal).first {
            let dinner = PlannedMeal(
                name: dinnerSuggestion.name,
                type: .dinner,
                carbs: dinnerSuggestion.carbs,
                protein: dinnerSuggestion.protein,
                calories: dinnerSuggestion.calories,
                notes: dinnerSuggestion.description,
                scheduledTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) ?? date
            )
            dailyMeals.append(dinner)
        }
        
        // Snack
        if let snackSuggestion = getMealSuggestions(for: .snack, targetCarbs: targetCarbsPerMeal * 0.5).first {
            let snack = PlannedMeal(
                name: snackSuggestion.name,
                type: .snack,
                carbs: snackSuggestion.carbs,
                protein: snackSuggestion.protein,
                calories: snackSuggestion.calories,
                notes: snackSuggestion.description,
                scheduledTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date
            )
            dailyMeals.append(snack)
        }
        
        return dailyMeals
    }
    
    // MARK: - Shopping List Generation
    
    func generateShoppingList(for dates: [Date]) -> [ShoppingListItem] {
        var ingredients: [String: ShoppingListItem] = [:]
        
        for date in dates {
            // Load meals for each date and extract ingredients
            // This is a simplified implementation
            let dayMeals = getAllMealsForDate(date)
            
            for meal in dayMeals {
                // Extract ingredients from meal (would need ingredient database)
                let mealIngredients = extractIngredients(from: meal)
                
                for ingredient in mealIngredients {
                    if let existingItem = ingredients[ingredient.name] {
                        ingredients[ingredient.name] = ShoppingListItem(
                            name: ingredient.name,
                            quantity: existingItem.quantity + ingredient.quantity,
                            unit: ingredient.unit,
                            category: ingredient.category
                        )
                    } else {
                        ingredients[ingredient.name] = ingredient
                    }
                }
            }
        }
        
        return Array(ingredients.values).sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    private func getAllMealsForDate(_ date: Date) -> [PlannedMeal] {
        // Implementation to get all meals for a specific date
        return []
    }
    
    private func extractIngredients(from meal: PlannedMeal) -> [ShoppingListItem] {
        // This would use a comprehensive ingredient database
        // For now, return sample ingredients based on meal name
        switch meal.name.lowercased() {
        case let name where name.contains("chicken"):
            return [
                ShoppingListItem(name: "Chicken Breast", quantity: 1, unit: "lb", category: .protein),
                ShoppingListItem(name: "Mixed Greens", quantity: 1, unit: "bag", category: .vegetables)
            ]
        case let name where name.contains("salmon"):
            return [
                ShoppingListItem(name: "Salmon Fillet", quantity: 1, unit: "lb", category: .protein),
                ShoppingListItem(name: "Broccoli", quantity: 1, unit: "head", category: .vegetables)
            ]
        default:
            return []
        }
    }
}

// MARK: - Supporting Models

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var icon: String {
        switch self {
        case .breakfast: return "sun.max.fill"
        case .lunch: return "sun.haze.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .yellow
        case .lunch: return .orange
        case .dinner: return .purple
        case .snack: return .green
        }
    }
}

struct PlannedMeal: Identifiable {
    let id = UUID()
    let name: String
    let type: MealType
    let carbs: Double
    let protein: Double
    let calories: Int
    let notes: String?
    let scheduledTime: Date
    
    var glucoseImpact: Int {
        // Simplified glucose impact calculation
        Int(carbs * 3) // Rough estimate: 1g carbs = ~3 mg/dL glucose rise
    }
    
    init(
        name: String,
        type: MealType,
        carbs: Double,
        protein: Double,
        calories: Int,
        notes: String? = nil,
        scheduledTime: Date
    ) {
        self.name = name
        self.type = type
        self.carbs = carbs
        self.protein = protein
        self.calories = calories
        self.notes = notes
        self.scheduledTime = scheduledTime
    }
    
    init?(from entity: MealEntity) {
        guard let name = entity.name,
              let typeString = entity.type,
              let type = MealType(rawValue: typeString),
              let timestamp = entity.timestamp else {
            return nil
        }
        
        self.name = name
        self.type = type
        self.carbs = entity.carbs
        self.protein = entity.protein
        self.calories = Int(entity.calories)
        self.notes = entity.notes
        self.scheduledTime = timestamp
    }
}

struct RecommendedMeal: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let carbs: Double
    let protein: Double
    let calories: Int
    let diabetesFriendly: Bool
    let glycemicIndex: GlycemicIndex
    let imageURL: String?
}

enum GlycemicIndex: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    
    var description: String {
        switch self {
        case .low: return "Low GI"
        case .medium: return "Medium GI"
        case .high: return "High GI"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

struct ShoppingListItem: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Double
    let unit: String
    let category: ShoppingCategory
}

enum ShoppingCategory: String, CaseIterable {
    case protein = "Protein"
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case grains = "Grains"
    case dairy = "Dairy"
    case pantry = "Pantry"
    case other = "Other"
}

// MARK: - Error Types

enum MealPlanningError: LocalizedError {
    case dataLoadFailed(String)
    case saveFailed(String)
    case noCurrentUser
    
    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let message):
            return "Failed to load meal data: \(message)"
        case .saveFailed(let message):
            return "Failed to save meal: \(message)"
        case .noCurrentUser:
            return "No current user found"
        }
    }
}