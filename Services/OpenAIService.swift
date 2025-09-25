import Foundation
import UIKit
import Combine

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    @Published var isAnalyzing = false
    @Published var currentAnalysis: MealAnalysisResult?
    @Published var error: OpenAIError?
    @Published var usageStats = UsageStats()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func analyzeMealImage(_ image: UIImage, retryCount: Int = 0) async throws -> MealAnalysisResult {
        await MainActor.run {
            isAnalyzing = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        // Validate API configuration
        guard APIConfig.isOpenAIConfigured else {
            throw OpenAIError.apiNotConfigured
        }
        
        // Validate and process image
        guard let processedImage = preprocessImage(image) else {
            throw OpenAIError.imageProcessingFailed
        }
        
        do {
            let result = try await performAnalysis(image: processedImage)
            
            // Update usage stats
            await updateUsageStats(result: result)
            
            // Cache result for offline access
            try await cacheAnalysisResult(result, for: image)
            
            await MainActor.run {
                currentAnalysis = result
            }
            
            return result
            
        } catch let error as OpenAIError {
            // Handle retryable errors
            if case .rateLimitExceeded = error, retryCount < 3 {
                let delay = pow(2.0, Double(retryCount)) // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await analyzeMealImage(image, retryCount: retryCount + 1)
            }
            
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        // Resize image to optimal size for API (max 2048x2048, maintain aspect ratio)
        let maxSize: CGFloat = 2048
        let size = image.size
        
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let scale = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func performAnalysis(image: UIImage) async throws -> MealAnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let request = OpenAIRequest(
            model: APIConfig.openAIModel,
            messages: [
                OpenAIMessage(
                    role: "user",
                    content: [
                        .text(buildAnalysisPrompt()),
                        .image(imageURL: "data:image/jpeg;base64,\(base64Image)")
                    ]
                )
            ],
            maxTokens: 3000,
            temperature: 0.2
        )
        
        let requestData = try encoder.encode(request)
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Diabfit/1.0", forHTTPHeaderField: "User-Agent")
        urlRequest.httpBody = requestData
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try parseSuccessResponse(data)
        case 400:
            throw OpenAIError.invalidRequest(try parseErrorResponse(data))
        case 401:
            throw OpenAIError.invalidAPIKey
        case 429:
            throw OpenAIError.rateLimitExceeded
        case 500...599:
            throw OpenAIError.serverError
        default:
            throw OpenAIError.unknownError(httpResponse.statusCode)
        }
    }
    
    private func parseSuccessResponse(_ data: Data) throws -> MealAnalysisResult {
        let response = try decoder.decode(OpenAIResponse.self, from: data)
        
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract JSON from the response content
        guard let jsonStart = content.range(of: "{"),
              let jsonEnd = content.range(of: "}", options: .backwards),
              jsonStart.lowerBound < jsonEnd.upperBound else {
            throw OpenAIError.invalidResponse
        }
        
        let jsonString = String(content[jsonStart.lowerBound...jsonEnd.upperBound])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        do {
            var analysis = try decoder.decode(MealAnalysisResult.self, from: jsonData)
            
            // Add metadata
            analysis.id = UUID()
            analysis.timestamp = Date()
            analysis.apiVersion = APIConfig.openAIModel
            analysis.processingTime = response.usage?.totalTokens ?? 0
            
            // Validate analysis result
            try validateAnalysisResult(analysis)
            
            return analysis
            
        } catch {
            throw OpenAIError.analysisParsingFailed(error.localizedDescription)
        }
    }
    
    private func parseErrorResponse(_ data: Data) throws -> String {
        if let errorResponse = try? decoder.decode(OpenAIErrorResponse.self, from: data) {
            return errorResponse.error.message
        }
        return "Unknown API error"
    }
    
    private func validateAnalysisResult(_ analysis: MealAnalysisResult) throws {
        // Validate confidence score
        guard analysis.confidence >= 0.0 && analysis.confidence <= 1.0 else {
            throw OpenAIError.invalidAnalysisData("Invalid confidence score")
        }
        
        // Validate nutritional data
        guard analysis.nutritionalAnalysis.totalCalories > 0 else {
            throw OpenAIError.invalidAnalysisData("Invalid calorie data")
        }
        
        // Validate glycemic data
        guard analysis.diabeticAnalysis.glycemicIndex.value >= 0 && 
              analysis.diabeticAnalysis.glycemicIndex.value <= 100 else {
            throw OpenAIError.invalidAnalysisData("Invalid glycemic index")
        }
        
        // Validate health scores
        guard analysis.healthScore.overall >= 0.0 && analysis.healthScore.overall <= 10.0 else {
            throw OpenAIError.invalidAnalysisData("Invalid health score")
        }
    }
    
    private func buildAnalysisPrompt() -> String {
        return """
        Analyze this meal image with extreme detail for a person with diabetes who may be using GLP-1 medications (like Ozempic, Wegovy, Mounjaro). You are a certified nutritionist and diabetes educator with expertise in GLP-1 medications.

        Provide a comprehensive analysis in the following JSON format. Be extremely accurate with portion sizes by comparing to common objects (credit card, tennis ball, deck of cards, etc.).

        {
          "mealIdentification": {
            "primaryDishes": ["dish1", "dish2"],
            "ingredients": ["ingredient1", "ingredient2", "ingredient3"],
            "cookingMethods": ["grilled", "fried", "steamed"],
            "estimatedPortionSizes": {
              "dish1": "6 oz (size of 2 decks of cards)",
              "dish2": "1 cup (size of tennis ball)"
            },
            "preparationNotes": "Visual cues about freshness, cooking level, seasoning"
          },
          "nutritionalAnalysis": {
            "totalCalories": 450,
            "macronutrients": {
              "carbohydrates": {"grams": 35.5, "percentage": 31.6},
              "protein": {"grams": 28.2, "percentage": 25.1},
              "fat": {"grams": 22.1, "percentage": 44.2},
              "fiber": {"grams": 8.3}
            },
            "micronutrients": {
              "sodium": "850mg",
              "potassium": "420mg",
              "calcium": "150mg",
              "iron": "3.2mg",
              "vitaminC": "25mg",
              "vitaminD": "2.1mcg",
              "magnesium": "45mg"
            },
            "sugar": {
              "total": "12.5g",
              "added": "2.1g", 
              "natural": "10.4g"
            },
            "cholesterol": "65mg",
            "saturatedFat": "6.2g",
            "transFat": "0.1g"
          },
          "diabeticAnalysis": {
            "glycemicIndex": {"value": 45, "category": "Low", "reasoning": "High fiber and protein content"},
            "glycemicLoad": {"value": 16, "category": "Medium", "reasoning": "Moderate carb content with good fiber"},
            "estimatedBloodSugarImpact": {
              "peakTime": "45-60 minutes",
              "expectedRise": "30-45 mg/dL",
              "duration": "2-3 hours",
              "factors": ["fiber content", "protein ratio", "fat content"]
            },
            "carbQuality": {
              "complexCarbs": "75%",
              "simpleCarbs": "25%",
              "fiberRatio": "23%",
              "netCarbs": "27.2g"
            },
            "insulinResponse": {
              "estimated": "moderate",
              "timing": "gradual over 2-3 hours",
              "factors": ["protein content", "fat content", "fiber"]
            }
          },
          "glp1Considerations": {
            "gastroparesis": {
              "risk": "Low",
              "reasoning": "Well-cooked proteins, moderate fiber, no high-fat content",
              "recommendations": ["Chew thoroughly", "Eat slowly"]
            },
            "satietyFactor": {
              "score": 8,
              "reasoning": "High protein and fiber content will enhance GLP-1's satiety effects",
              "duration": "4-6 hours"
            },
            "digestionTime": {
              "estimated": "3-4 hours",
              "impact": "May extend satiety period due to GLP-1 effects",
              "considerations": ["Delayed gastric emptying possible"]
            },
            "nausea": {
              "risk": "Low",
              "factors": ["Low fat content", "Not overly spiced", "Familiar foods"]
            },
            "recommendations": [
              "Eat slowly to allow GLP-1 satiety signals to register",
              "Stop eating when 80% full due to delayed satiety signals",
              "Monitor for delayed gastric emptying symptoms",
              "Ideal meal timing 2-3 hours before next injection"
            ]
          },
          "healthScore": {
            "overall": 7.5,
            "diabeticFriendly": 8.0,
            "glp1Compatible": 8.5,
            "nutritionalDensity": 7.8,
            "reasoning": "Well-balanced meal with good protein-to-carb ratio, moderate glycemic impact"
          },
          "recommendations": {
            "portionAdjustments": [
              "Consider reducing rice portion by 25% to lower carb load",
              "Add more non-starchy vegetables for volume and nutrients"
            ],
            "timingAdvice": [
              "Best consumed 2-3 hours before next GLP-1 injection",
              "Allow 20-30 minutes eating time for proper satiety signaling",
              "Avoid eating within 2 hours of bedtime"
            ],
            "modifications": [
              "Replace white rice with cauliflower rice to reduce carbs by 80%",
              "Add avocado slices for healthy fats and satiety",
              "Include a small side salad to increase fiber"
            ],
            "bloodSugarManagement": [
              "Check glucose 1-2 hours post-meal for peak response",
              "Consider pre-meal glucose reading for comparison",
              "Log meal timing and glucose response for pattern recognition"
            ],
            "medicationTiming": [
              "If taking rapid-acting insulin, dose for 27g net carbs",
              "GLP-1 users: monitor for extended satiety effects",
              "Consider meal timing with other diabetes medications"
            ]
          },
          "warnings": [
            "High sodium content may cause water retention and affect blood pressure",
            "Monitor for delayed gastric emptying if on GLP-1 medications",
            "Portion size appears large - consider eating half and saving remainder"
          ],
          "confidence": 0.85,
          "analysisNotes": "Analysis based on visual assessment. Actual nutritional content may vary based on preparation methods and exact ingredients used."
        }

        Be extremely detailed and specific. Estimate portion sizes carefully by comparing to common objects. Consider visual cues for cooking methods, ingredient freshness, and preparation style. For GLP-1 users, focus on gastroparesis risk, satiety enhancement, and optimal timing considerations. Provide actionable, specific recommendations.
        """
    }
    
    private func updateUsageStats(result: MealAnalysisResult) async {
        await MainActor.run {
            usageStats.totalAnalyses += 1
            usageStats.totalTokensUsed += result.processingTime
            usageStats.averageConfidence = (usageStats.averageConfidence * Double(usageStats.totalAnalyses - 1) + result.confidence) / Double(usageStats.totalAnalyses)
            usageStats.lastAnalysisDate = Date()
        }
        
        // Save usage stats
        UserDefaults.standard.set(try? encoder.encode(usageStats), forKey: "openai_usage_stats")
    }
    
    private func cacheAnalysisResult(_ result: MealAnalysisResult, for image: UIImage) async throws {
        let cacheManager = AnalysisCacheManager.shared
        try await cacheManager.cacheResult(result, image: image)
    }
    
    func getUsageEstimate() -> UsageEstimate {
        let costPerAnalysis = 0.02 // Approximate cost in USD
        let monthlyAnalyses = usageStats.totalAnalyses // Simplified for demo
        
        return UsageEstimate(
            analysesThisMonth: monthlyAnalyses,
            estimatedMonthlyCost: Double(monthlyAnalyses) * costPerAnalysis,
            tokensUsed: usageStats.totalTokensUsed,
            averageConfidence: usageStats.averageConfidence
        )
    }
}

// MARK: - Data Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: [MessageContent]
}

enum MessageContent: Codable {
    case text(String)
    case image(imageURL: String)
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageURL = "image_url"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let imageURL):
            try container.encode("image_url", forKey: .type)
            var imageContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .imageURL)
            try imageContainer.encode(imageURL, forKey: .imageURL)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image_url":
            let imageContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .imageURL)
            let imageURL = try imageContainer.decode(String.self, forKey: .imageURL)
            self = .image(imageURL: imageURL)
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown content type"))
        }
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String?
        }
    }
    
    struct Usage: Codable {
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case totalTokens = "total_tokens"
        }
    }
}

struct OpenAIErrorResponse: Codable {
    let error: APIError
    
    struct APIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

struct UsageStats: Codable {
    var totalAnalyses: Int = 0
    var totalTokensUsed: Int = 0
    var averageConfidence: Double = 0.0
    var lastAnalysisDate: Date?
}

struct UsageEstimate {
    let analysesThisMonth: Int
    let estimatedMonthlyCost: Double
    let tokensUsed: Int
    let averageConfidence: Double
}

enum OpenAIError: LocalizedError {
    case apiNotConfigured
    case imageProcessingFailed
    case networkError
    case invalidRequest(String)
    case invalidAPIKey
    case rateLimitExceeded
    case serverError
    case unknownError(Int)
    case invalidResponse
    case analysisParsingFailed(String)
    case invalidAnalysisData(String)
    
    var errorDescription: String? {
        switch self {
        case .apiNotConfigured:
            return "OpenAI API key not configured. Please check your API configuration."
        case .imageProcessingFailed:
            return "Failed to process the image. Please try with a different image."
        case .networkError:
            return "Network error occurred. Please check your internet connection."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key configuration."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment before trying again."
        case .serverError:
            return "OpenAI server error. Please try again later."
        case .unknownError(let code):
            return "Unknown error occurred (Code: \(code)). Please try again."
        case .invalidResponse:
            return "Invalid response from OpenAI. Please try again."
        case .analysisParsingFailed(let error):
            return "Failed to parse analysis result: \(error)"
        case .invalidAnalysisData(let message):
            return "Invalid analysis data: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .apiNotConfigured:
            return "Configure your OpenAI API key in the app settings."
        case .imageProcessingFailed:
            return "Try taking a clearer photo with better lighting."
        case .networkError:
            return "Check your internet connection and try again."
        case .invalidAPIKey:
            return "Verify your OpenAI API key is correct and has sufficient credits."
        case .rateLimitExceeded:
            return "Wait a few minutes before analyzing another meal."
        case .serverError:
            return "OpenAI services may be temporarily unavailable. Try again in a few minutes."
        default:
            return "Try again or contact support if the problem persists."
        }
    }
}