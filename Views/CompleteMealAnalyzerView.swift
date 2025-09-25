import SwiftUI
import UIKit

struct CompleteMealAnalyzerView: View {
    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var cacheManager = AnalysisCacheManager.shared
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var selectedAnalysis: MealAnalysisResult?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                        headerSection
                        
                        // API Status Section
                        apiStatusSection
                        
                        // Camera Controls
                        cameraControlsSection
                        
                        // Current Analysis Section
                        if let image = capturedImage {
                            currentAnalysisSection(image: image)
                        }
                        
                        // Usage Statistics
                        usageStatisticsSection
                        
                        // Feature Information
                        featureInformationSection
                        
                        // Recent Analyses
                        recentAnalysesSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Meal Analyzer")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $capturedImage, isPresented: $showingCamera)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryView(image: $capturedImage, isPresented: $showingPhotoLibrary)
        }
        .sheet(isPresented: $showingHistory) {
            AnalysisHistoryView()
        }
        .sheet(isPresented: $showingSettings) {
            AnalyzerSettingsView()
        }
        .sheet(item: $selectedAnalysis) { analysis in
            DetailedAnalysisView(analysis: analysis)
        }
        .onChange(of: capturedImage) { image in
            if let image = image {
                Task {
                    await analyzeImage(image)
                }
            }
        }
        .alert("Analysis Error", isPresented: .constant(openAIService.error != nil)) {
            Button("OK") {
                openAIService.error = nil
            }
            if let error = openAIService.error, error.recoverySuggestion != nil {
                Button("Help") {
                    // Show help or retry options
                }
            }
        } message: {
            if let error = openAIService.error {
                VStack(alignment: .leading) {
                    Text(error.localizedDescription)
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            
            Text("AI Meal Analyzer")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Advanced meal analysis powered by GPT-4 Vision for comprehensive diabetes and GLP-1 insights")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    private var apiStatusSection: some View {
        HStack {
            Image(systemName: APIConfig.isOpenAIConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(APIConfig.isOpenAIConfigured ? .green : .orange)
            
            Text(APIConfig.isOpenAIConfigured ? "OpenAI API Connected" : "API Configuration Required")
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            if APIConfig.isOpenAIConfigured {
                Text("Ready for Analysis")
                    .font(.caption2)
                    .foregroundColor(.green)
            } else {
                Button("Configure") {
                    showingSettings = true
                }
                .font(.caption2)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(8)
    }
    
    private var cameraControlsSection: some View {
        VStack(spacing: 15) {
            Text("Capture Your Meal")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                Button(action: { showingCamera = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Take Photo")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!APIConfig.isOpenAIConfigured)
                
                Button(action: { showingPhotoLibrary = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.title2)
                        Text("Photo Library")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(APIConfig.isOpenAIConfigured ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!APIConfig.isOpenAIConfigured)
            }
            
            if !APIConfig.isOpenAIConfigured {
                Text("Configure your OpenAI API key to enable meal analysis")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
    
    private func currentAnalysisSection(image: UIImage) -> some View {
        VStack(spacing: 15) {
            Text("Current Analysis")
                .font(.headline)
                .foregroundColor(.white)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            if openAIService.isAnalyzing {
                VStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
                        .scaleEffect(1.2)
                    
                    Text("Analyzing your meal...")
                        .foregroundColor(.white)
                    
                    Text("This may take 10-30 seconds")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Processing with GPT-4 Vision for comprehensive analysis")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let analysis = openAIService.currentAnalysis {
                CompactAnalysisResultView(analysis: analysis) {
                    selectedAnalysis = analysis
                }
            } else if let error = openAIService.error {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("Analysis Failed")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack {
                        Button("Try Again") {
                            Task {
                                await analyzeImage(image)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("New Photo") {
                            capturedImage = nil
                            openAIService.currentAnalysis = nil
                            openAIService.error = nil
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            if openAIService.currentAnalysis != nil || openAIService.error != nil {
                Button("Analyze New Photo") {
                    capturedImage = nil
                    openAIService.currentAnalysis = nil
                    openAIService.error = nil
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var usageStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Usage Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            let stats = cacheManager.getAnalysisStatistics()
            let usage = openAIService.getUsageEstimate()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "Total Analyses", value: "\(stats.totalAnalyses)", icon: "chart.bar.fill", color: .blue)
                StatCard(title: "Avg Confidence", value: "\(Int(stats.averageConfidence * 100))%", icon: "checkmark.seal.fill", color: .green)
                StatCard(title: "Avg Calories", value: "\(Int(stats.averageCalories))", icon: "flame.fill", color: .orange)
                StatCard(title: "Monthly Cost", value: "$\(String(format: "%.2f", usage.estimatedMonthlyCost))", icon: "dollarsign.circle.fill", color: .purple)
            }
        }
    }
    
    private var featureInformationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Analysis Features")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                FeatureCard(
                    icon: "pills.fill",
                    title: "GLP-1 Optimization",
                    description: "Gastroparesis risk assessment, satiety scoring, and optimal meal timing for GLP-1 medications.",
                    color: .blue
                )
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Blood Sugar Prediction",
                    description: "Detailed glycemic index, load, and predicted blood sugar response with timing.",
                    color: .orange
                )
                
                FeatureCard(
                    icon: "leaf.fill",
                    title: "Nutritional Analysis",
                    description: "Complete macro and micronutrient breakdown with portion size estimation.",
                    color: Color(red: 0.7, green: 0.9, blue: 0.3)
                )
                
                FeatureCard(
                    icon: "brain.head.profile",
                    title: "AI-Powered Insights",
                    description: "GPT-4 Vision provides expert-level nutritional analysis and personalized recommendations.",
                    color: .purple
                )
            }
        }
    }
    
    private var recentAnalysesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Analyses")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingHistory = true
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            let recentAnalyses = cacheManager.exportAnalysisHistory().prefix(3)
            
            if recentAnalyses.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray.opacity(0.6))
                    Text("No analyses yet")
                        .foregroundColor(Color.gray.opacity(0.8))
                    Text("Take a photo of your meal to get started")
                        .font(.caption)
                        .foregroundColor(Color.gray.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ForEach(Array(recentAnalyses), id: \.id) { entry in
                    RecentAnalysisCard(entry: entry) {
                        if let cachedResult = cacheManager.getCachedResult(for: entry.id.uuidString) {
                            selectedAnalysis = cachedResult
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func analyzeImage(_ image: UIImage) async {
        do {
            let result = try await openAIService.analyzeMealImage(image)
            // Result is automatically stored in openAIService.currentAnalysis
        } catch {
            // Error is automatically stored in openAIService.error
            print("Analysis failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct CompactAnalysisResultView: View {
    let analysis: MealAnalysisResult
    let onTapForDetails: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Analysis Complete")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(analysis.mealIdentification.primaryDishes.first ?? "Unknown Meal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    Text("\(Int(analysis.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                QuickStat(title: "Calories", value: "\(analysis.nutritionalAnalysis.totalCalories)", color: .blue)
                QuickStat(title: "Carbs", value: "\(Int(analysis.nutritionalAnalysis.macronutrients.carbohydrates.grams))g", color: .orange)
                QuickStat(title: "GI", value: "\(analysis.diabeticAnalysis.glycemicIndex.value)", color: glycemicColor(analysis.diabeticAnalysis.glycemicIndex.category))
                QuickStat(title: "GLP-1", value: String(format: "%.1f", analysis.healthScore.glp1Compatible), color: Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            // Key Recommendations Preview
            if !analysis.recommendations.portionAdjustments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Recommendation")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text(analysis.recommendations.portionAdjustments.first ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            
            // Tap for Details
            Button(action: onTapForDetails) {
                HStack {
                    Text("View Detailed Analysis")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func glycemicColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "low": return .green
        case "medium": return .yellow
        case "high": return .red
        default: return .gray
        }
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RecentAnalysisCard: View {
    let entry: AnalysisHistoryEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.dishName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("Confidence: \(Int(entry.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(entry.calories) cal")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("GLP-1: \(String(format: "%.1f", entry.glp1Score))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CompleteMealAnalyzerView()
}