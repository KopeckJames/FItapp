import SwiftUI

struct AnalysisHistoryView: View {
    @StateObject private var cacheManager = AnalysisCacheManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnalysis: MealAnalysisResult?
    @State private var showingExportOptions = false
    @State private var searchText = ""
    
    private var filteredHistory: [AnalysisHistoryEntry] {
        let history = cacheManager.exportAnalysisHistory()
        
        if searchText.isEmpty {
            return history
        } else {
            return history.filter { entry in
                entry.dishName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Statistics Header
                    statisticsHeader
                    
                    // Search Bar
                    searchBar
                    
                    // History List
                    if filteredHistory.isEmpty {
                        emptyStateView
                    } else {
                        historyList
                    }
                }
            }
            .navigationTitle("Analysis History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingExportOptions = true }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: clearAllHistory) {
                            Label("Clear All History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    }
                }
            }
        }
        .sheet(item: $selectedAnalysis) { analysis in
            DetailedAnalysisView(analysis: analysis)
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
        }
    }
    
    private var statisticsHeader: some View {
        let stats = cacheManager.getAnalysisStatistics()
        
        return VStack(spacing: 15) {
            Text("Your Analysis Journey")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                StatisticCard(
                    title: "Total",
                    value: "\(stats.totalAnalyses)",
                    subtitle: "Analyses",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Average",
                    value: "\(Int(stats.averageConfidence * 100))%",
                    subtitle: "Confidence",
                    color: .green
                )
                
                StatisticCard(
                    title: "Average",
                    value: String(format: "%.1f", stats.averageDiabeticScore),
                    subtitle: "Diabetic Score",
                    color: .orange
                )
            }
            
            if !stats.mostCommonDishes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Analyzed Dishes")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(stats.mostCommonDishes.prefix(5), id: \.self) { dish in
                                Text(dish)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.2))
                                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search meals...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredHistory) { entry in
                    HistoryEntryCard(entry: entry) {
                        loadAndShowAnalysis(for: entry)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(Color.gray.opacity(0.6))
            
            Text(searchText.isEmpty ? "No Analyses Yet" : "No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(searchText.isEmpty ? 
                 "Start analyzing your meals to build your personal nutrition history" :
                 "Try adjusting your search terms")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if searchText.isEmpty {
                Button("Analyze Your First Meal") {
                    dismiss()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                .foregroundColor(.white)
                .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadAndShowAnalysis(for entry: AnalysisHistoryEntry) {
        if let analysis = cacheManager.getCachedResult(for: entry.id.uuidString) {
            selectedAnalysis = analysis
        }
    }
    
    private func clearAllHistory() {
        cacheManager.clearAllCache()
    }
}

struct HistoryEntryCard: View {
    let entry: AnalysisHistoryEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Meal Image Placeholder or Thumbnail
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.dishName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 15) {
                        Label("\(entry.calories)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Label("\(Int(entry.confidence * 100))%", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("D:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(String(format: "%.1f", entry.diabeticScore))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("G:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(String(format: "%.1f", entry.glp1Score))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    }
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

struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cacheManager = AnalysisCacheManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(spacing: 15) {
                        ExportOptionCard(
                            title: "CSV Export",
                            description: "Export analysis data in spreadsheet format",
                            icon: "tablecells",
                            action: exportCSV
                        )
                        
                        ExportOptionCard(
                            title: "PDF Report",
                            description: "Generate a comprehensive nutrition report",
                            icon: "doc.text",
                            action: exportPDF
                        )
                        
                        ExportOptionCard(
                            title: "Share Summary",
                            description: "Share your nutrition insights with healthcare providers",
                            icon: "square.and.arrow.up",
                            action: shareSummary
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Export Options")
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
    
    private func exportCSV() {
        // Implementation for CSV export
        let history = cacheManager.exportAnalysisHistory()
        // Create CSV data and share
    }
    
    private func exportPDF() {
        // Implementation for PDF export
        let stats = cacheManager.getAnalysisStatistics()
        // Generate PDF report
    }
    
    private func shareSummary() {
        // Implementation for sharing summary
        let stats = cacheManager.getAnalysisStatistics()
        // Create shareable summary
    }
}

struct ExportOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
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
    AnalysisHistoryView()
}