import SwiftUI

struct MealPlanningView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var mealPlanningService = MealPlanningService()
    
    @State private var selectedDate = Date()
    @State private var showingAddMeal = false
    @State private var showingMealSuggestions = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Date selector
                    dateSelector
                    
                    // Daily nutrition summary
                    dailyNutritionSummary
                    
                    // Meal plan for selected date
                    mealPlanSection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Meal suggestions
                    mealSuggestionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .navigationTitle("Meal Planning")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddMeal = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView(
                selectedDate: selectedDate,
                mealPlanningService: mealPlanningService
            )
        }
        .sheet(isPresented: $showingMealSuggestions) {
            MealSuggestionsView(mealPlanningService: mealPlanningService)
        }
        .onAppear {
            mealPlanningService.loadMealsForDate(selectedDate)
        }
        .onChange(of: selectedDate) { _ in
            mealPlanningService.loadMealsForDate(selectedDate)
        }
    }
    
    // MARK: - Date Selector
    
    private var dateSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: previousDay) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
                
                Spacer()
                
                Text(selectedDate, style: .date)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextDay) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
            }
            
            if Calendar.current.isDateInToday(selectedDate) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            } else if Calendar.current.isDateInTomorrow(selectedDate) {
                Text("Tomorrow")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else if Calendar.current.isDateInYesterday(selectedDate) {
                Text("Yesterday")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Daily Nutrition Summary
    
    private var dailyNutritionSummary: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Nutrition")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View Details") {
                    // Navigate to detailed nutrition view
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            HStack(spacing: 20) {
                NutritionSummaryItem(
                    title: "Carbs",
                    current: mealPlanningService.dailyCarbs,
                    target: mealPlanningService.carbsTarget,
                    unit: "g",
                    color: .orange
                )
                
                NutritionSummaryItem(
                    title: "Protein",
                    current: mealPlanningService.dailyProtein,
                    target: mealPlanningService.proteinTarget,
                    unit: "g",
                    color: .blue
                )
                
                NutritionSummaryItem(
                    title: "Calories",
                    current: mealPlanningService.dailyCalories,
                    target: mealPlanningService.caloriesTarget,
                    unit: "",
                    color: Color(red: 0.7, green: 0.9, blue: 0.3)
                )
            }
            
            // Glucose impact prediction
            if mealPlanningService.predictedGlucoseImpact > 0 {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.red)
                    
                    Text("Predicted glucose impact: +\(mealPlanningService.predictedGlucoseImpact) mg/dL")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Meal Plan Section
    
    private var mealPlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Plan")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                MealTypeSection(
                    mealType: .breakfast,
                    meals: mealPlanningService.breakfastMeals,
                    onAddMeal: { showingAddMeal = true }
                )
                
                MealTypeSection(
                    mealType: .lunch,
                    meals: mealPlanningService.lunchMeals,
                    onAddMeal: { showingAddMeal = true }
                )
                
                MealTypeSection(
                    mealType: .dinner,
                    meals: mealPlanningService.dinnerMeals,
                    onAddMeal: { showingAddMeal = true }
                )
                
                MealTypeSection(
                    mealType: .snack,
                    meals: mealPlanningService.snackMeals,
                    onAddMeal: { showingAddMeal = true }
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    icon: "camera.viewfinder",
                    title: "Scan Meal",
                    description: "Use AI to analyze food",
                    color: Color(red: 0.7, green: 0.9, blue: 0.3)
                ) {
                    // Navigate to meal analyzer
                }
                
                QuickActionButton(
                    icon: "lightbulb.fill",
                    title: "Get Suggestions",
                    description: "Diabetes-friendly meals",
                    color: .blue
                ) {
                    showingMealSuggestions = true
                }
                
                QuickActionButton(
                    icon: "calendar",
                    title: "Plan Week",
                    description: "Weekly meal planning",
                    color: .purple
                ) {
                    // Navigate to weekly planner
                }
                
                QuickActionButton(
                    icon: "list.bullet.clipboard",
                    title: "Shopping List",
                    description: "Generate grocery list",
                    color: .orange
                ) {
                    // Navigate to shopping list
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Meal Suggestions Section
    
    private var mealSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended for You")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                    showingMealSuggestions = true
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mealPlanningService.recommendedMeals.prefix(5), id: \.id) { meal in
                        MealSuggestionCard(meal: meal) {
                            // Add meal to plan
                            mealPlanningService.addMealToPlan(meal, for: selectedDate)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}

// MARK: - Supporting Views

struct NutritionSummaryItem: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(Int(current))\(unit)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("of \(Int(target))\(unit)")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealTypeSection: View {
    let mealType: MealType
    let meals: [PlannedMeal]
    let onAddMeal: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(mealType.color)
                
                Text(mealType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onAddMeal) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
            }
            
            if meals.isEmpty {
                HStack {
                    Text("No meals planned")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button("Add Meal") {
                        onAddMeal()
                    }
                    .font(.caption)
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                VStack(spacing: 4) {
                    ForEach(meals, id: \.id) { meal in
                        PlannedMealRow(meal: meal)
                    }
                }
            }
        }
    }
}

struct PlannedMealRow: View {
    let meal: PlannedMeal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.body)
                    .foregroundColor(.white)
                
                HStack {
                    Text("\(Int(meal.carbs))g carbs")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("• \(meal.calories) cal")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if meal.glucoseImpact > 0 {
                VStack(alignment: trailing, spacing: 2) {
                    Text("+\(meal.glucoseImpact)")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text("mg/dL")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MealSuggestionCard: View {
    let meal: RecommendedMeal
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: meal.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 120, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Text("\(Int(meal.carbs))g")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("\(meal.calories)cal")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Button("Add") {
                    onAdd()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .frame(width: 120)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Add Meal View

struct AddMealView: View {
    let selectedDate: Date
    @ObservedObject var mealPlanningService: MealPlanningService
    @Environment(\.dismiss) private var dismiss
    
    @State private var mealName = ""
    @State private var selectedMealType = MealType.breakfast
    @State private var carbs = ""
    @State private var protein = ""
    @State private var calories = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            TextField("Meal name", text: $mealName)
                                .textFieldStyle(CustomMealTextFieldStyle())
                            
                            Picker("Meal Type", selection: $selectedMealType) {
                                ForEach(MealType.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
                                    }
                                    .tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .colorScheme(.dark)
                            
                            HStack(spacing: 12) {
                                TextField("Carbs (g)", text: $carbs)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(CustomMealTextFieldStyle())
                                
                                TextField("Protein (g)", text: $protein)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(CustomMealTextFieldStyle())
                                
                                TextField("Calories", text: $calories)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomMealTextFieldStyle())
                            }
                            
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .textFieldStyle(CustomMealTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                        
                        Button("Add Meal") {
                            addMeal()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .cornerRadius(12)
                        .disabled(mealName.isEmpty)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
    
    private func addMeal() {
        let meal = PlannedMeal(
            name: mealName,
            type: selectedMealType,
            carbs: Double(carbs) ?? 0,
            protein: Double(protein) ?? 0,
            calories: Int(calories) ?? 0,
            notes: notes.isEmpty ? nil : notes,
            scheduledTime: selectedDate
        )
        
        mealPlanningService.addMealToPlan(meal, for: selectedDate)
        dismiss()
    }
}

struct CustomMealTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

// MARK: - Meal Suggestions View

struct MealSuggestionsView: View {
    @ObservedObject var mealPlanningService: MealPlanningService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mealPlanningService.recommendedMeals, id: \.id) { meal in
                            RecommendedMealCard(meal: meal) {
                                // Add to meal plan
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Meal Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
            }
        }
    }
}

struct RecommendedMealCard: View {
    let meal: RecommendedMeal
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: meal.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(meal.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    NutritionBadge(value: "\(Int(meal.carbs))g", label: "Carbs", color: .orange)
                    NutritionBadge(value: "\(Int(meal.protein))g", label: "Protein", color: .blue)
                    NutritionBadge(value: "\(meal.calories)", label: "Cal", color: .green)
                }
            }
            
            Spacer()
            
            Button("Add") {
                onAdd()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.7, green: 0.9, blue: 0.3))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

struct NutritionBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    MealPlanningView()
        .preferredColorScheme(.dark)
}