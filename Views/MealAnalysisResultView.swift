import SwiftUI

struct MealAnalysisResultView: View {
    let analysis: MealAnalysisResult
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with confidence score
            HStack {
                VStack(alignment: .leading) {
                    Text("Analysis Complete")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Confidence: \(Int(analysis.confidence * 100))%")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: analysis.confidence,
                    color: Color(red: 0.7, green: 0.9, blue: 0.3)
                )
                .frame(width: 50, height: 50)
            }
            
            // Tab Selection
            Picker("Analysis Sections", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Nutrition").tag(1)
                Text("Diabetes").tag(2)
                Text("GLP-1").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorScheme(.dark)
            
            // Content based on selected tab
            ScrollView {
                switch selectedTab {
                case 0:
                    OverviewSection(analysis: analysis)
                case 1:
                    NutritionSection(analysis: analysis)
                case 2:
                    DiabetesSection(analysis: analysis)
                case 3:
                    GLP1Section(analysis: analysis)
                default:
                    OverviewSection(analysis: analysis)
                }
            }
            .frame(maxHeight: 400)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct OverviewSection: View {
    let analysis: MealAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Meal Identification
            VStack(alignment: .leading, spacing: 10) {
                Text("Meal Identification")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(analysis.mealIdentification.primaryDishes, id: \.self) { dish in
                        HStack {
                            Image(systemName: "fork.knife")
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                            Text(dish)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Health Scores
            VStack(alignment: .leading, spacing: 10) {
                Text("Health Scores")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 15) {
                    ScoreCard(
                        title: "Overall",
                        score: analysis.healthScore.overall,
                        color: .blue
                    )
                    
                    ScoreCard(
                        title: "Diabetic",
                        score: analysis.healthScore.diabeticFriendly,
                        color: .orange
                    )
                    
                    ScoreCard(
                        title: "GLP-1",
                        score: analysis.healthScore.glp1Compatible,
                        color: Color(red: 0.7, green: 0.9, blue: 0.3)
                    )
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Key Recommendations
            VStack(alignment: .leading, spacing: 10) {
                Text("Key Recommendations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(analysis.recommendations.portionAdjustments.prefix(3), id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(recommendation)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Warnings
            if !analysis.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Important Warnings")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    ForEach(analysis.warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}

struct NutritionSection: View {
    let analysis: MealAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Calories and Macros
            VStack(alignment: .leading, spacing: 10) {
                Text("Macronutrients")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    MacroBar(
                        name: "Carbohydrates",
                        grams: analysis.nutritionalAnalysis.macronutrients.carbohydrates.grams,
                        percentage: analysis.nutritionalAnalysis.macronutrients.carbohydrates.percentage,
                        color: .orange
                    )
                    
                    MacroBar(
                        name: "Protein",
                        grams: analysis.nutritionalAnalysis.macronutrients.protein.grams,
                        percentage: analysis.nutritionalAnalysis.macronutrients.protein.percentage,
                        color: .red
                    )
                    
                    MacroBar(
                        name: "Fat",
                        grams: analysis.nutritionalAnalysis.macronutrients.fat.grams,
                        percentage: analysis.nutritionalAnalysis.macronutrients.fat.percentage,
                        color: .purple
                    )
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Calories and Fiber
            HStack(spacing: 20) {
                VStack {
                    Text("\(analysis.nutritionalAnalysis.totalCalories)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                
                VStack {
                    Text("\(Int(analysis.nutritionalAnalysis.macronutrients.fiber.grams))g")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Fiber")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.2))
                .cornerRadius(8)
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Micronutrients
            VStack(alignment: .leading, spacing: 10) {
                Text("Key Micronutrients")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    MicronutrientCard(name: "Sodium", value: analysis.nutritionalAnalysis.micronutrients.sodium)
                    MicronutrientCard(name: "Potassium", value: analysis.nutritionalAnalysis.micronutrients.potassium)
                    MicronutrientCard(name: "Calcium", value: analysis.nutritionalAnalysis.micronutrients.calcium)
                    MicronutrientCard(name: "Iron", value: analysis.nutritionalAnalysis.micronutrients.iron)
                }
            }
        }
    }
}

struct DiabetesSection: View {
    let analysis: MealAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Glycemic Information
            VStack(alignment: .leading, spacing: 10) {
                Text("Glycemic Impact")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 15) {
                    GlycemicCard(
                        title: "Glycemic Index",
                        value: analysis.diabeticAnalysis.glycemicIndex.value,
                        category: analysis.diabeticAnalysis.glycemicIndex.category,
                        color: glycemicColor(analysis.diabeticAnalysis.glycemicIndex.category)
                    )
                    
                    GlycemicCard(
                        title: "Glycemic Load",
                        value: analysis.diabeticAnalysis.glycemicLoad.value,
                        category: analysis.diabeticAnalysis.glycemicLoad.category,
                        color: glycemicColor(analysis.diabeticAnalysis.glycemicLoad.category)
                    )
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Blood Sugar Impact
            VStack(alignment: .leading, spacing: 10) {
                Text("Predicted Blood Sugar Response")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    BloodSugarInfoRow(
                        icon: "clock.fill",
                        title: "Peak Time",
                        value: analysis.diabeticAnalysis.estimatedBloodSugarImpact.peakTime,
                        color: .blue
                    )
                    
                    BloodSugarInfoRow(
                        icon: "arrow.up.circle.fill",
                        title: "Expected Rise",
                        value: analysis.diabeticAnalysis.estimatedBloodSugarImpact.expectedRise,
                        color: .orange
                    )
                    
                    BloodSugarInfoRow(
                        icon: "timer",
                        title: "Duration",
                        value: analysis.diabeticAnalysis.estimatedBloodSugarImpact.duration,
                        color: .purple
                    )
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Carb Quality
            VStack(alignment: .leading, spacing: 10) {
                Text("Carbohydrate Quality")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    CarbQualityRow(title: "Complex Carbs", percentage: analysis.diabeticAnalysis.carbQuality.complexCarbs)
                    CarbQualityRow(title: "Simple Carbs", percentage: analysis.diabeticAnalysis.carbQuality.simpleCarbs)
                    CarbQualityRow(title: "Fiber Ratio", percentage: analysis.diabeticAnalysis.carbQuality.fiberRatio)
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Blood Sugar Management Tips
            VStack(alignment: .leading, spacing: 10) {
                Text("Blood Sugar Management")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(analysis.recommendations.bloodSugarManagement, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "drop.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func glycemicColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "low":
            return .green
        case "medium":
            return .yellow
        case "high":
            return .red
        default:
            return .gray
        }
    }
}

struct GLP1Section: View {
    let analysis: MealAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Gastroparesis Risk
            VStack(alignment: .leading, spacing: 10) {
                Text("Gastroparesis Assessment")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Risk Level: \(analysis.glp1Considerations.gastroparesis.risk)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(riskColor(analysis.glp1Considerations.gastroparesis.risk))
                        
                        Text(analysis.glp1Considerations.gastroparesis.reasoning)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: riskIcon(analysis.glp1Considerations.gastroparesis.risk))
                        .font(.title2)
                        .foregroundColor(riskColor(analysis.glp1Considerations.gastroparesis.risk))
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Satiety Factor
            VStack(alignment: .leading, spacing: 10) {
                Text("Satiety Enhancement")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Satiety Score:")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text("\(analysis.glp1Considerations.satietyFactor.score)/10")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                        }
                        
                        Text(analysis.glp1Considerations.satietyFactor.reasoning)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: Double(analysis.glp1Considerations.satietyFactor.score) / 10.0,
                        color: Color(red: 0.7, green: 0.9, blue: 0.3)
                    )
                    .frame(width: 40, height: 40)
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Digestion Time
            VStack(alignment: .leading, spacing: 10) {
                Text("Digestion Timeline")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Estimated Time: \(analysis.glp1Considerations.digestionTime.estimated)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    Text(analysis.glp1Considerations.digestionTime.impact)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // GLP-1 Specific Recommendations
            VStack(alignment: .leading, spacing: 10) {
                Text("GLP-1 Recommendations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(analysis.glp1Considerations.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "pills.fill")
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                            .font(.caption)
                        
                        Text(recommendation)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Timing Advice
            VStack(alignment: .leading, spacing: 10) {
                Text("Optimal Timing")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(analysis.recommendations.timingAdvice, id: \.self) { advice in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(advice)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func riskColor(_ risk: String) -> Color {
        switch risk.lowercased() {
        case "low":
            return .green
        case "medium":
            return .yellow
        case "high":
            return .red
        default:
            return .gray
        }
    }
    
    private func riskIcon(_ risk: String) -> String {
        switch risk.lowercased() {
        case "low":
            return "checkmark.circle.fill"
        case "medium":
            return "exclamationmark.triangle.fill"
        case "high":
            return "xmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Supporting Views

struct ScoreCard: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", score))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

struct MacroBar: View {
    let name: String
    let grams: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(String(format: "%.1f", grams))g (\(Int(percentage))%)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

struct MicronutrientCard: View {
    let name: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(6)
    }
}

struct GlycemicCard: View {
    let title: String
    let value: Int
    let category: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(category)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

struct BloodSugarInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct CarbQualityRow: View {
    let title: String
    let percentage: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(percentage)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
        }
        .padding(.vertical, 2)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    let sampleAnalysis = MealAnalysisResult(
        mealIdentification: MealIdentification(
            primaryDishes: ["Grilled Chicken Salad"],
            ingredients: ["Chicken breast", "Mixed greens", "Tomatoes"],
            cookingMethods: ["Grilled"],
            estimatedPortionSizes: ["Chicken": "6 oz", "Salad": "2 cups"]
        ),
        nutritionalAnalysis: NutritionalAnalysis(
            totalCalories: 350,
            macronutrients: Macronutrients(
                carbohydrates: MacroDetail(grams: 15, percentage: 17),
                protein: MacroDetail(grams: 45, percentage: 51),
                fat: MacroDetail(grams: 12, percentage: 31),
                fiber: FiberDetail(grams: 8)
            ),
            micronutrients: Micronutrients(
                sodium: "650mg",
                potassium: "420mg",
                calcium: "150mg",
                iron: "3mg",
                vitaminC: "25mg"
            ),
            sugar: SugarBreakdown(total: "8g", added: "0g", natural: "8g")
        ),
        diabeticAnalysis: DiabeticAnalysis(
            glycemicIndex: GlycemicValue(value: 35, category: "Low"),
            glycemicLoad: GlycemicValue(value: 5, category: "Low"),
            estimatedBloodSugarImpact: BloodSugarImpact(
                peakTime: "30-45 minutes",
                expectedRise: "15-25 mg/dL",
                duration: "1-2 hours"
            ),
            carbQuality: CarbQuality(
                complexCarbs: "80%",
                simpleCarbs: "20%",
                fiberRatio: "53%"
            )
        ),
        glp1Considerations: GLP1Considerations(
            gastroparesis: GastroparesisRisk(risk: "Low", reasoning: "Well-cooked proteins and moderate fiber"),
            satietyFactor: SatietyFactor(score: 9, reasoning: "High protein content enhances GLP-1 effects"),
            digestionTime: DigestionTime(estimated: "2-3 hours", impact: "Optimal for GLP-1 users"),
            recommendations: ["Eat slowly", "Monitor for satiety"]
        ),
        healthScore: HealthScore(
            overall: 8.5,
            diabeticFriendly: 9.0,
            glp1Compatible: 9.2,
            reasoning: "Excellent balance for diabetes management"
        ),
        recommendations: Recommendations(
            portionAdjustments: ["Perfect portion size"],
            timingAdvice: ["Best consumed 2-3 hours before injection"],
            modifications: ["Add avocado for healthy fats"],
            bloodSugarManagement: ["Check glucose 1-2 hours post-meal"]
        ),
        warnings: [],
        confidence: 0.92
    )
    
    MealAnalysisResultView(analysis: sampleAnalysis)
}