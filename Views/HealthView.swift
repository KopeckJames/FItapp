import SwiftUI
import HealthKit

struct HealthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var healthService = HealthService()
    
    @State private var heartRate = ""
    @State private var systolicBP = ""
    @State private var diastolicBP = ""
    @State private var weight = ""
    @State private var temperature = ""
    @State private var selectedTime = Date()
    @State private var isLoading = false
    @State private var showingHealthKitError = false
    @State private var healthKitErrorMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // HealthKit status
                    healthKitStatusCard
                    
                    // Health metrics input
                    healthMetricsInputCard
                    
                    // Recent health data
                    recentHealthDataCard
                    
                    // Health insights
                    healthInsightsCard
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .navigationTitle("Health Metrics")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            Task {
                await healthService.requestHealthKitPermissions()
            }
        }
        .alert("HealthKit Error", isPresented: $showingHealthKitError) {
            Button("OK") { }
        } message: {
            Text(healthKitErrorMessage)
        }
    }
    
    // MARK: - HealthKit Status Card
    
    private var healthKitStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(healthService.isHealthKitAuthorized ? Color(red: 0.7, green: 0.9, blue: 0.3) : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health Integration")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(healthService.isHealthKitAuthorized ? "Connected and syncing" : "Not connected")
                        .font(.caption)
                        .foregroundColor(healthService.isHealthKitAuthorized ? Color(red: 0.7, green: 0.9, blue: 0.3) : .gray)
                }
                
                Spacer()
                
                if healthService.isHealthKitAuthorized {
                    Button("Sync Now") {
                        Task {
                            await healthService.syncFromHealthKit()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                } else {
                    Button("Connect") {
                        Task {
                            await healthService.requestHealthKitPermissions()
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
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
    
    // MARK: - Health Metrics Input Card
    
    private var healthMetricsInputCard: some View {
        VStack(spacing: 15) {
            Text("Log Health Data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Heart Rate (bpm)")
                        .foregroundColor(.white)
                    Spacer()
                    TextField("BPM", text: $heartRate)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomHealthTextFieldStyle())
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Blood Pressure")
                        .foregroundColor(.white)
                    Spacer()
                    HStack {
                        TextField("Sys", text: $systolicBP)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomHealthTextFieldStyle())
                            .frame(width: 70)
                        Text("/")
                            .foregroundColor(.white)
                        TextField("Dia", text: $diastolicBP)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomHealthTextFieldStyle())
                            .frame(width: 70)
                    }
                }
                
                HStack {
                    Text("Weight (lbs)")
                        .foregroundColor(.white)
                    Spacer()
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(CustomHealthTextFieldStyle())
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Temperature (°F)")
                        .foregroundColor(.white)
                    Spacer()
                    TextField("Temp", text: $temperature)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(CustomHealthTextFieldStyle())
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Time")
                        .foregroundColor(.white)
                    Spacer()
                    DatePicker("", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .colorScheme(.dark)
                }
            }
            
            Button(action: {
                Task {
                    await saveHealthData()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Save Health Data")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading || !hasValidInput)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Recent Health Data Card
    
    private var recentHealthDataCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Health Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to detailed health history
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            if healthService.recentHealthMetrics.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray.opacity(0.6))
                    Text("No health data yet")
                        .foregroundColor(Color.gray.opacity(0.8))
                    Text("Add your first health metrics above")
                        .font(.caption)
                        .foregroundColor(Color.gray.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                VStack(spacing: 8) {
                    ForEach(healthService.recentHealthMetrics.prefix(5), id: \.id) { metric in
                        HealthMetricRow(metric: metric)
                    }
                }
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
    
    // MARK: - Health Insights Card
    
    private var healthInsightsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Health Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HealthInsightCard(
                    icon: "heart.fill",
                    title: "Heart Rate Trends",
                    description: healthService.heartRateInsight,
                    color: .red
                )
                
                HealthInsightCard(
                    icon: "drop.fill",
                    title: "Blood Pressure",
                    description: healthService.bloodPressureInsight,
                    color: .blue
                )
                
                HealthInsightCard(
                    icon: "scalemass.fill",
                    title: "Weight Management",
                    description: healthService.weightInsight,
                    color: .green
                )
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
    
    // MARK: - Helper Methods
    
    private var hasValidInput: Bool {
        !heartRate.isEmpty || !systolicBP.isEmpty || !diastolicBP.isEmpty || !weight.isEmpty || !temperature.isEmpty
    }
    
    private func saveHealthData() async {
        guard let user = authViewModel.currentUser else { return }
        
        isLoading = true
        
        do {
            let heartRateValue = Int(heartRate)
            let systolicValue = Int(systolicBP)
            let diastolicValue = Int(diastolicBP)
            let weightValue = Double(weight)
            let temperatureValue = Double(temperature)
            
            await healthService.saveHealthMetrics(
                heartRate: heartRateValue,
                systolicBP: systolicValue,
                diastolicBP: diastolicValue,
                weight: weightValue,
                temperature: temperatureValue,
                timestamp: selectedTime
            )
            
            // Clear form
            heartRate = ""
            systolicBP = ""
            diastolicBP = ""
            weight = ""
            temperature = ""
            selectedTime = Date()
            
        } catch {
            healthKitErrorMessage = error.localizedDescription
            showingHealthKitError = true
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct CustomHealthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}

struct HealthMetricRow: View {
    let metric: HealthMetric
    
    var body: some View {
        HStack {
            Image(systemName: metric.icon)
                .font(.title3)
                .foregroundColor(metric.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(metric.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(metric.displayValue)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

struct HealthInsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
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
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Models
// HealthMetric is now defined in HealthModels.swift

@MainActor
class HealthService: ObservableObject {
    @Published var isHealthKitAuthorized = false
    @Published var recentHealthMetrics: [HealthMetric] = []
    @Published var heartRateInsight = "Track your heart rate to monitor cardiovascular health"
    @Published var bloodPressureInsight = "Regular blood pressure monitoring helps prevent complications"
    @Published var weightInsight = "Maintain a healthy weight for better diabetes management"
    @Published var isLoading = false
    
    init() {
        // Initialize with sample data for now
        loadSampleData()
    }
    
    func requestHealthKitPermissions() async {
        // Placeholder implementation
        isHealthKitAuthorized = true
    }
    
    func saveHealthMetrics(
        heartRate: Int? = nil,
        systolicBP: Int? = nil,
        diastolicBP: Int? = nil,
        weight: Double? = nil,
        temperature: Double? = nil,
        timestamp: Date = Date()
    ) async throws {
        // Placeholder implementation
        if let heartRate = heartRate {
            let metric = HealthMetric(id: UUID(), type: "heart_rate", value: Double(heartRate), unit: "bpm", timestamp: timestamp)
            recentHealthMetrics.append(metric)
        }
        if let systolicBP = systolicBP {
            let metric = HealthMetric(id: UUID(), type: "systolic_bp", value: Double(systolicBP), unit: "mmHg", timestamp: timestamp)
            recentHealthMetrics.append(metric)
        }
        if let weight = weight {
            let metric = HealthMetric(id: UUID(), type: "weight", value: weight, unit: "lbs", timestamp: timestamp)
            recentHealthMetrics.append(metric)
        }
    }
    
    func syncFromHealthKit() async {
        // Placeholder implementation
    }
    
    private func loadSampleData() {
        // Add some sample data
        recentHealthMetrics = [
            HealthMetric(id: UUID(), type: "heart_rate", value: 72, unit: "bpm", timestamp: Date()),
            HealthMetric(id: UUID(), type: "systolic_bp", value: 120, unit: "mmHg", timestamp: Date()),
            HealthMetric(id: UUID(), type: "weight", value: 150, unit: "lbs", timestamp: Date())
        ]
    }
}

#Preview {
    HealthView()
        .preferredColorScheme(.dark)
}