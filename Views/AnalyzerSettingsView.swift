import SwiftUI

struct AnalyzerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAIService = OpenAIService.shared
    @State private var apiKey = APIConfig.openAIAPIKey
    @State private var showingAPIKeyInput = false
    @State private var tempAPIKey = ""
    @State private var showingUsageDetails = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // API Configuration Section
                        apiConfigurationSection
                        
                        // Usage Statistics Section
                        usageStatisticsSection
                        
                        // Analysis Settings Section
                        analysisSettingsSection
                        
                        // Privacy & Data Section
                        privacyDataSection
                        
                        // About Section
                        aboutSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Analyzer Settings")
            .navigationBarTitleDisplayMode(.large)
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
        .sheet(isPresented: $showingAPIKeyInput) {
            APIKeyInputView(apiKey: $tempAPIKey) { newKey in
                updateAPIKey(newKey)
            }
        }
        .sheet(isPresented: $showingUsageDetails) {
            UsageDetailsView()
        }
    }
    
    private var apiConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("API Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: APIConfig.isOpenAIConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(APIConfig.isOpenAIConfigured ? .green : .orange)
                    
                    VStack(alignment: .leading) {
                        Text("OpenAI API Status")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text(APIConfig.isOpenAIConfigured ? "Connected and Ready" : "API Key Required")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(APIConfig.isOpenAIConfigured ? "Update" : "Configure") {
                        tempAPIKey = APIConfig.isOpenAIConfigured ? "••••••••••••••••" : ""
                        showingAPIKeyInput = true
                    }
                    .font(.caption)
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)
                
                if APIConfig.isOpenAIConfigured {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key Preview")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("sk-••••••••••••••••••••••••••••••••••••••••••••••••")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                // API Setup Instructions
                if !APIConfig.isOpenAIConfigured {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Setup Instructions")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Visit platform.openai.com/api-keys")
                            Text("2. Create a new API key")
                            Text("3. Copy and paste it above")
                            Text("4. Ensure you have sufficient credits")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private var usageStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Usage & Billing")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Details") {
                    showingUsageDetails = true
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            let usage = openAIService.getUsageEstimate()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                UsageCard(
                    title: "This Month",
                    value: "\(usage.analysesThisMonth)",
                    subtitle: "Analyses",
                    color: .blue
                )
                
                UsageCard(
                    title: "Estimated Cost",
                    value: "$\(String(format: "%.2f", usage.estimatedMonthlyCost))",
                    subtitle: "USD",
                    color: .green
                )
                
                UsageCard(
                    title: "Tokens Used",
                    value: "\(usage.tokensUsed)",
                    subtitle: "Total",
                    color: .orange
                )
                
                UsageCard(
                    title: "Avg Confidence",
                    value: "\(Int(usage.averageConfidence * 100))%",
                    subtitle: "Accuracy",
                    color: .purple
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Cost Information")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Each analysis costs approximately $0.01-0.03")
                    Text("• Costs depend on image size and complexity")
                    Text("• Monitor usage at platform.openai.com/usage")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var analysisSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Analysis Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SettingRow(
                    title: "Cache Results",
                    description: "Store analysis results locally for offline access",
                    isEnabled: .constant(true),
                    action: { _ in }
                )
                
                SettingRow(
                    title: "High Accuracy Mode",
                    description: "Use more detailed prompts for better accuracy (higher cost)",
                    isEnabled: .constant(true),
                    action: { _ in }
                )
                
                SettingRow(
                    title: "Auto-Save Images",
                    description: "Automatically save analyzed meal images",
                    isEnabled: .constant(false),
                    action: { _ in }
                )
            }
        }
    }
    
    private var privacyDataSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Privacy & Data")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ActionRow(
                    title: "Clear Analysis Cache",
                    description: "Remove all locally stored analysis results",
                    icon: "trash",
                    color: .orange,
                    action: clearCache
                )
                
                ActionRow(
                    title: "Export Data",
                    description: "Export your analysis history and statistics",
                    icon: "square.and.arrow.up",
                    color: .blue,
                    action: exportData
                )
                
                ActionRow(
                    title: "Privacy Policy",
                    description: "Learn how your data is handled",
                    icon: "hand.raised",
                    color: .green,
                    action: showPrivacyPolicy
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Data Handling")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Images are sent to OpenAI for analysis")
                    Text("• No images are permanently stored by OpenAI")
                    Text("• Analysis results are cached locally")
                    Text("• You can delete all data at any time")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("About")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                InfoRow(title: "Version", value: "1.0.0")
                InfoRow(title: "AI Model", value: "GPT-4 Vision")
                InfoRow(title: "Last Updated", value: Date().formatted(date: .abbreviated, time: .omitted))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Features")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("✓ Advanced meal recognition and analysis")
                    Text("✓ Diabetes-specific nutritional insights")
                    Text("✓ GLP-1 medication considerations")
                    Text("✓ Personalized recommendations")
                    Text("✓ Comprehensive health scoring")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateAPIKey(_ newKey: String) {
        // In a real app, this would securely store the API key
        // For now, we'll just update the config
        print("API Key updated: \(newKey.prefix(10))...")
    }
    
    private func clearCache() {
        AnalysisCacheManager.shared.clearAllCache()
    }
    
    private func exportData() {
        // Implementation for data export
    }
    
    private func showPrivacyPolicy() {
        // Implementation to show privacy policy
    }
}

// MARK: - Supporting Views

struct UsageCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
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

struct SettingRow: View {
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let action: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
                .onChange(of: isEnabled) { value in
                    action(value)
                }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

struct ActionRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var inputKey = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("OpenAI API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your OpenAI API key")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        SecureField("sk-...", text: $inputKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to get your API key:")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Go to platform.openai.com/api-keys")
                            Text("2. Click 'Create new secret key'")
                            Text("3. Copy the key and paste it above")
                            Text("4. Make sure you have billing set up")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("API Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(inputKey)
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .disabled(inputKey.isEmpty)
                }
            }
        }
        .onAppear {
            inputKey = apiKey == "••••••••••••••••" ? "" : apiKey
        }
    }
}

struct UsageDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAIService = OpenAIService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Usage Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        let usage = openAIService.getUsageEstimate()
                        
                        VStack(spacing: 15) {
                            DetailCard(title: "Total Analyses", value: "\(usage.analysesThisMonth)", description: "Meals analyzed this month")
                            DetailCard(title: "Total Tokens", value: "\(usage.tokensUsed)", description: "API tokens consumed")
                            DetailCard(title: "Average Cost", value: "$0.02", description: "Per analysis (estimated)")
                            DetailCard(title: "Monthly Estimate", value: "$\(String(format: "%.2f", usage.estimatedMonthlyCost))", description: "Based on current usage")
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cost Breakdown")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Image processing: ~$0.01-0.02 per analysis")
                                Text("• Text generation: ~$0.005-0.01 per analysis")
                                Text("• Total per analysis: ~$0.015-0.03")
                                Text("• Costs vary based on image complexity")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Usage Details")
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

struct DetailCard: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

#Preview {
    AnalyzerSettingsView()
}