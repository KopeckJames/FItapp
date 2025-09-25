import Foundation

struct APIConfig {
    // MARK: - OpenAI Configuration
    static let openAIAPIKey = "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" // Replace with your actual API key
    static let openAIBaseURL = "https://api.openai.com/v1/chat/completions"
    static let openAIModel = "gpt-4-vision-preview"
    
    // MARK: - API Configuration Validation
    static var isOpenAIConfigured: Bool {
        return !openAIAPIKey.isEmpty && openAIAPIKey != "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"
    }
    
    // MARK: - Usage Guidelines
    /*
     To use the AI Meal Analyzer:
     
     1. Get an OpenAI API key:
        - Go to https://platform.openai.com/api-keys
        - Create a new API key
        - Replace "YOUR_OPENAI_API_KEY_HERE" above with your actual key
     
     2. Ensure you have sufficient credits:
        - The GPT-4 Vision model is required for image analysis
        - Each analysis costs approximately $0.01-0.03 depending on image size
        - Monitor your usage at https://platform.openai.com/usage
     
     3. Security considerations:
        - Never commit your actual API key to version control
        - Consider using environment variables or secure storage in production
        - Implement rate limiting to prevent excessive API calls
     
     4. Privacy compliance:
        - Inform users that meal images are sent to OpenAI for analysis
        - Ensure compliance with local privacy laws (GDPR, CCPA, etc.)
        - Consider implementing local image processing for sensitive data
     */
}