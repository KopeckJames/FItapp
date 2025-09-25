import Foundation
import UIKit

class MealAnalyzerService: ObservableObject {
    private let openAIAPIKey = APIConfig.openAIAPIKey
    private let baseURL = APIConfig.openAIBaseURL
    
    @Published var isAnalyzing = false
    @Published var analysisResult: MealAnalysisResult?
    @Published var errorMessage: String?
    
    func analyzeMealImage(_ image: UIImage) async {
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            analysisResult = nil
        }
        
        do {
            let result = await performAnalysis(image: image)
            await MainActor.run {
                self.analysisResult = result
                self.isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isAnalyzing = false
            }
        }
    }
    
    private func performAnalysis(image: UIImage) async throws -> MealAnalysisResult {
        // Check if API is configured
        guard APIConfig.isOpenAIConfigured else {
            throw MealAnalyzerError.apiNotConfigured
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MealAnalyzerError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Analyze this meal image with extreme detail for a person with diabetes who may be using GLP-1 medications (like Ozempic, Wegovy, Mounjaro). Provide a comprehensive analysis in the following JSON format:

        {
          "mealIdentification": {
            "primaryDishes": ["dish1", "dish2"],
            "ingredients": ["ingredient1", "ingredient2"],
            "cookingMethods": ["grilled", "fried", "steamed"],
            "estimatedPortionSizes": {
              "dish1": "6 oz",
              "dish2": "1 cup"
            }
          },
          "nutritionalAnalysis": {
            "totalCalories": 450,
            "macronutrients": {
              "carbohydrates": {"grams": 35, "percentage": 31},
              "protein": {"grams": 28, "percentage": 25},
              "fat": {"grams": 22, "percentage": 44},
              "fiber": {"grams": 8}
            },
            "micronutrients": {
              "sodium": "850mg",
              "potassium": "420mg",
              "calcium": "150mg",
              "iron": "3mg",
              "vitaminC": "25mg"
            },
            "sugar": {"total": "12g", "added": "2g", "natural": "10g"}
          },
          "diabeticAnalysis": {
            "glycemicIndex": {"value": 45, "category": "Low"},
            "glycemicLoad": {"value": 16, "category": "Medium"},
            "estimatedBloodSugarImpact": {
              "peakTime": "45-60 minutes",
              "expectedRise": "30-45 mg/dL",
              "duration": "2-3 hours"
            },
            "carbQuality": {
              "complexCarbs": "75%",
              "simpleCarbs": "25%",
              "fiberRatio": "23%"
            }
          },
          "glp1Considerations": {
            "gastroparesis": {
              "risk": "Low",
              "reasoning": "Moderate fiber content, well-cooked proteins"
            },
            "satietyFactor": {
              "score": 8,
              "reasoning": "High protein and fiber content will enhance GLP-1's satiety effects"
            },
            "digestionTime": {
              "estimated": "3-4 hours",
              "impact": "May extend satiety period due to GLP-1 effects"
            },
            "recommendations": [
              "Eat slowly to allow GLP-1 satiety signals to register",
              "Consider smaller portion if experiencing nausea",
              "Monitor for delayed gastric emptying"
            ]
          },
          "healthScore": {
            "overall": 7.5,
            "diabeticFriendly": 8.0,
            "glp1Compatible": 8.5,
            "reasoning": "Well-balanced meal with good protein-to-carb ratio"
          },
          "recommendations": {
            "portionAdjustments": [
              "Consider reducing rice portion by 25% to lower carb load",
              "Add more non-starchy vegetables for volume"
            ],
            "timingAdvice": [
              "Best consumed 2-3 hours before next GLP-1 injection",
              "Allow 20-30 minutes eating time for proper satiety signaling"
            ],
            "modifications": [
              "Replace white rice with cauliflower rice to reduce carbs",
              "Add avocado for healthy fats and satiety"
            ],
            "bloodSugarManagement": [
              "Check glucose 1-2 hours post-meal",
              "Consider pre-meal glucose reading for comparison"
            ]
          },
          "warnings": [
            "High sodium content may cause water retention",
            "Monitor for delayed gastric emptying if on GLP-1"
          ],
          "confidence": 0.85
        }

        Be extremely detailed and specific. Estimate portion sizes carefully by comparing to common objects. Consider the visual cues for cooking methods, ingredient freshness, and preparation style. For GLP-1 users, focus on gastroparesis risk, satiety enhancement, and optimal timing considerations.
        """
        
        let requestBody: [String: Any] = [
            "model": APIConfig.openAIModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.3
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw MealAnalyzerError.requestCreationFailed
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MealAnalyzerError.apiRequestFailed
        }
        
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw MealAnalyzerError.responseParsingFailed
        }
        
        // Parse the JSON response from OpenAI
        guard let analysisData = content.data(using: .utf8),
              let analysis = try? JSONDecoder().decode(MealAnalysisResult.self, from: analysisData) else {
            throw MealAnalyzerError.analysisParsingFailed
        }
        
        return analysis
    }
}

enum MealAnalyzerError: LocalizedError {
    case imageProcessingFailed
    case requestCreationFailed
    case apiRequestFailed
    case responseParsingFailed
    case analysisParsingFailed
    case apiNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .requestCreationFailed:
            return "Failed to create API request"
        case .apiRequestFailed:
            return "API request failed"
        case .responseParsingFailed:
            return "Failed to parse API response"
        case .analysisParsingFailed:
            return "Failed to parse meal analysis"
        case .apiNotConfigured:
            return "OpenAI API key not configured. Please check APIConfig.swift"
        }
    }
}