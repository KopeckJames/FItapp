# AI Meal Analyzer Setup Guide

## Overview
The AI Meal Analyzer uses OpenAI's GPT-4 Vision model to provide comprehensive meal analysis specifically tailored for individuals with diabetes, including those using GLP-1 medications.

## Features

### 🔍 Detailed Meal Analysis
- **Meal Identification**: Recognizes dishes, ingredients, and cooking methods
- **Portion Size Estimation**: Accurate portion sizing using visual cues
- **Nutritional Breakdown**: Complete macro and micronutrient analysis
- **Calorie Calculation**: Precise calorie estimation based on visual assessment

### 🩺 Diabetes-Specific Insights
- **Glycemic Index & Load**: Detailed carbohydrate impact analysis
- **Blood Sugar Prediction**: Expected glucose response timing and magnitude
- **Carbohydrate Quality**: Complex vs simple carb breakdown with fiber ratios
- **Diabetes-Friendly Scoring**: Overall meal compatibility rating

### 💊 GLP-1 Medication Considerations
- **Gastroparesis Risk Assessment**: Evaluates meal digestibility for GLP-1 users
- **Satiety Factor Analysis**: How the meal enhances GLP-1's appetite suppression
- **Digestion Timeline**: Expected digestion duration with GLP-1 effects
- **Timing Recommendations**: Optimal meal timing relative to medication schedule

### 📊 Comprehensive Recommendations
- **Portion Adjustments**: Specific suggestions for better glucose control
- **Meal Modifications**: Ingredient substitutions and preparation changes
- **Blood Sugar Management**: Monitoring and testing recommendations
- **Safety Warnings**: Important alerts for high-risk combinations

## Setup Instructions

### 1. OpenAI API Configuration
1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create a new API key
3. Open `FItapp/Config/APIConfig.swift`
4. Replace `"YOUR_OPENAI_API_KEY_HERE"` with your actual API key

```swift
static let openAIAPIKey = "sk-your-actual-api-key-here"
```

### 2. Camera Permissions
Add these permissions to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to analyze your meals for diabetes management.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to analyze meal images for diabetes insights.</string>
```

### 3. Cost Considerations
- Each analysis costs approximately $0.01-0.03
- Monitor usage at [OpenAI Usage Dashboard](https://platform.openai.com/usage)
- Consider implementing rate limiting for production use

### 4. Privacy & Security
- Meal images are sent to OpenAI for analysis
- No images are stored by OpenAI after processing
- Ensure compliance with local privacy regulations
- Consider user consent flows for data processing

## Usage Flow

1. **Capture Image**: Take photo or select from library
2. **AI Analysis**: Image sent to GPT-4 Vision for processing
3. **Detailed Results**: Comprehensive analysis displayed in tabs:
   - **Overview**: Key insights and health scores
   - **Nutrition**: Detailed macro/micronutrient breakdown
   - **Diabetes**: Glycemic impact and blood sugar predictions
   - **GLP-1**: Medication-specific considerations

## Technical Architecture

### Core Components
- `MealAnalyzerService`: Handles OpenAI API communication
- `MealAnalyzerView`: Main camera and analysis interface
- `MealAnalysisResultView`: Detailed results display with tabs
- `CameraView`: Native camera integration
- `MealAnalysisModels`: Comprehensive data structures

### Data Models
- `MealAnalysisResult`: Complete analysis response
- `NutritionalAnalysis`: Macro/micronutrient data
- `DiabeticAnalysis`: Glycemic and blood sugar impact
- `GLP1Considerations`: Medication-specific insights
- `Recommendations`: Actionable advice and modifications

### Error Handling
- Image processing failures
- API connectivity issues
- Response parsing errors
- Configuration validation

## Best Practices

### For Users
- Take clear, well-lit photos of complete meals
- Include all components and sides in the image
- Provide context through notes when needed
- Monitor actual blood sugar response vs predictions

### For Developers
- Implement proper error handling and user feedback
- Add loading states for better UX
- Consider offline fallback options
- Implement usage analytics and monitoring
- Add user rating system for analysis accuracy

## Future Enhancements

### Planned Features
- **Analysis History**: Track meal patterns over time
- **Accuracy Feedback**: User rating system for continuous improvement
- **Personalization**: Learn from individual glucose responses
- **Integration**: Connect with glucose monitors and health apps
- **Offline Mode**: Local analysis for privacy-sensitive users

### Advanced Analytics
- **Trend Analysis**: Identify patterns in meal choices and glucose response
- **Personalized Recommendations**: AI-driven suggestions based on history
- **Correlation Insights**: Link meals to actual blood sugar data
- **Progress Tracking**: Monitor diabetes management improvements

## Troubleshooting

### Common Issues
1. **"API key not configured"**: Update APIConfig.swift with valid key
2. **Camera not working**: Check Info.plist permissions
3. **Analysis fails**: Verify internet connection and API credits
4. **Slow responses**: Normal for detailed analysis (10-30 seconds)

### Support Resources
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [GPT-4 Vision Guide](https://platform.openai.com/docs/guides/vision)
- [iOS Camera Integration](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture)

## Compliance & Legal

### Privacy Considerations
- Implement clear data usage policies
- Provide opt-out mechanisms
- Consider GDPR/CCPA compliance requirements
- Document data retention policies

### Medical Disclaimer
This tool provides educational information only and should not replace professional medical advice. Users should consult healthcare providers for diabetes management decisions.