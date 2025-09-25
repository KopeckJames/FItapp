import SwiftUI
import UIKit

struct MealAnalyzerView: View {
    @StateObject private var analyzerService = MealAnalyzerService()
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingImagePicker = false
    @State private var analysisHistory: [HistorySession] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                        VStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 50))
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                            
                            Text("AI Meal Analyzer")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Snap a photo of your meal for detailed diabetes-friendly analysis")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // Camera Controls
                        VStack(spacing: 15) {
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
                                
                                Button(action: { showingPhotoLibrary = true }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.fill")
                                            .font(.title2)
                                        Text("Photo Library")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Current Analysis Section
                        if let image = capturedImage {
                            VStack(spacing: 15) {
                                Text("Captured Image")
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
                                
                                if analyzerService.isAnalyzing {
                                    VStack(spacing: 10) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
                                            .scaleEffect(1.2)
                                        
                                        Text("Analyzing your meal...")
                                            .foregroundColor(.white)
                                        
                                        Text("This may take 10-30 seconds")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                } else if let analysis = analyzerService.analysisResult {
                                    MealAnalysisResultView(analysis: analysis)
                                } else if let error = analyzerService.errorMessage {
                                    VStack(spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                        
                                        Text("Analysis Failed")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                        
                                        Button("Try Again") {
                                            Task {
                                                await analyzerService.analyzeMealImage(image)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .padding()
                                }
                                
                                Button("Analyze New Photo") {
                                    capturedImage = nil
                                    analyzerService.analysisResult = nil
                                    analyzerService.errorMessage = nil
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // GLP-1 Information Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("GLP-1 & Diabetes Insights")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                InfoCard(
                                    icon: "pills.fill",
                                    title: "GLP-1 Considerations",
                                    description: "Our analysis considers gastroparesis risk, satiety enhancement, and optimal meal timing for GLP-1 users.",
                                    color: .blue
                                )
                                
                                InfoCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Blood Sugar Impact",
                                    description: "Get detailed glycemic index, load, and predicted blood sugar response timing.",
                                    color: .orange
                                )
                                
                                InfoCard(
                                    icon: "leaf.fill",
                                    title: "Portion Analysis",
                                    description: "Accurate portion size estimation and recommendations for optimal diabetes management.",
                                    color: Color(red: 0.7, green: 0.9, blue: 0.3)
                                )
                            }
                        }
                        
                        // Analysis History Preview
                        if !analysisHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("Recent Analyses")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button("View All") {
                                        // Navigate to full history
                                    }
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                                }
                                
                                ForEach(analysisHistory.prefix(3)) { session in
                                    HistoryPreviewCard(session: session)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Meal Analyzer")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $capturedImage, isPresented: $showingCamera)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryView(image: $capturedImage, isPresented: $showingPhotoLibrary)
        }
        .onChange(of: capturedImage) { image in
            if let image = image {
                Task {
                    await analyzerService.analyzeMealImage(image)
                }
            }
        }
    }
}

struct InfoCard: View {
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

struct HistoryPreviewCard: View {
    let session: HistorySession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.analysis.mealIdentification.primaryDishes.first ?? "Unknown Meal")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("Confidence: \(Int(session.analysis.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    
                    if let rating = session.userRating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.analysis.nutritionalAnalysis.totalCalories) cal")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("GI: \(session.analysis.diabeticAnalysis.glycemicIndex.value)")
                    .font(.caption)
                    .foregroundColor(.orange)
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
}

#Preview {
    MealAnalyzerView()
}