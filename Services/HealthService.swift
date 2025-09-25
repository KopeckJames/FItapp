import Foundation
import HealthKit
import Combine

@MainActor
public class HealthService: ObservableObject {
    @Published var isHealthKitAuthorized = false
    @Published var recentHealthMetrics: [HealthMetric] = []
    @Published var heartRateInsight = "Track your heart rate to monitor cardiovascular health"
    @Published var bloodPressureInsight = "Regular blood pressure monitoring helps prevent complications"
    @Published var weightInsight = "Maintain a healthy weight for better diabetes management"
    @Published var isLoading = false
    @Published var error: HealthError?
    
    private let healthStore = HKHealthStore()
    private let coreDataManager = CoreDataManager.shared
    private var currentUser: UserEntity?
    
    init() {
        self.currentUser = coreDataManager.getCurrentUser()
        checkHealthKitAuthorization()
        loadRecentHealthMetrics()
    }
    
    // MARK: - HealthKit Authorization
    
    func requestHealthKitPermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.error = .healthKitNotAvailable
            }
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                self.isHealthKitAuthorized = true
            }
            await syncFromHealthKit()
        } catch {
            await MainActor.run {
                self.error = .authorizationFailed(error.localizedDescription)
            }
        }
    }
    
    private func checkHealthKitAuthorization() {
        isHealthKitAuthorized = HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Health Metrics Management
    
    func saveHealthMetrics(
        heartRate: Int? = nil,
        systolicBP: Int? = nil,
        diastolicBP: Int? = nil,
        weight: Double? = nil,
        temperature: Double? = nil,
        timestamp: Date = Date()
    ) async throws {
        guard let user = currentUser else {
            throw HealthError.noCurrentUser
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Save to Core Data
        coreDataManager.saveHealthMetric(
            systolicBP: systolicBP,
            diastolicBP: diastolicBP,
            heartRate: heartRate,
            weight: weight,
            temperature: temperature,
            timestamp: timestamp,
            for: user
        )
        
        // Save to HealthKit if authorized
        if isHealthKitAuthorized {
            try await saveToHealthKit(
                heartRate: heartRate,
                systolicBP: systolicBP,
                diastolicBP: diastolicBP,
                weight: weight,
                temperature: temperature,
                timestamp: timestamp
            )
        }
        
        // Reload recent metrics
        loadRecentHealthMetrics()
        updateInsights()
    }
    
    private func saveToHealthKit(
        heartRate: Int? = nil,
        systolicBP: Int? = nil,
        diastolicBP: Int? = nil,
        weight: Double? = nil,
        temperature: Double? = nil,
        timestamp: Date
    ) async throws {
        var samples: [HKSample] = []
        
        if let heartRate = heartRate {
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: Double(heartRate))
            let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: timestamp, end: timestamp)
            samples.append(heartRateSample)
        }
        
        if let systolicBP = systolicBP {
            let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
            let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(systolicBP))
            let systolicSample = HKQuantitySample(type: systolicType, quantity: systolicQuantity, start: timestamp, end: timestamp)
            samples.append(systolicSample)
        }
        
        if let diastolicBP = diastolicBP {
            let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
            let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(diastolicBP))
            let diastolicSample = HKQuantitySample(type: diastolicType, quantity: diastolicQuantity, start: timestamp, end: timestamp)
            samples.append(diastolicSample)
        }
        
        if let weight = weight {
            let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
            let weightQuantity = HKQuantity(unit: HKUnit.pound(), doubleValue: weight)
            let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: timestamp, end: timestamp)
            samples.append(weightSample)
        }
        
        if let temperature = temperature {
            let tempType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
            let tempQuantity = HKQuantity(unit: HKUnit.degreeFahrenheit(), doubleValue: temperature)
            let tempSample = HKQuantitySample(type: tempType, quantity: tempQuantity, start: timestamp, end: timestamp)
            samples.append(tempSample)
        }
        
        if !samples.isEmpty {
            try await healthStore.save(samples)
        }
    }
    
    func syncFromHealthKit() async {
        guard isHealthKitAuthorized else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Sync heart rate data
            await syncHeartRateData()
            
            // Sync blood pressure data
            await syncBloodPressureData()
            
            // Sync weight data
            await syncWeightData()
            
            // Sync temperature data
            await syncTemperatureData()
            
            // Reload recent metrics
            loadRecentHealthMetrics()
            updateInsights()
            
        } catch {
            await MainActor.run {
                self.error = .syncFailed(error.localizedDescription)
            }
        }
    }
    
    private func syncHeartRateData() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -30, to: Date()), end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let samples = samples as? [HKQuantitySample] {
                    // Process and save heart rate samples
                    for sample in samples {
                        let heartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                        // Save to Core Data if not already exists
                    }
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }
    
    private func syncBloodPressureData() async {
        // Similar implementation for blood pressure
    }
    
    private func syncWeightData() async {
        // Similar implementation for weight
    }
    
    private func syncTemperatureData() async {
        // Similar implementation for temperature
    }
    
    // MARK: - Data Loading
    
    private func loadRecentHealthMetrics() {
        guard let user = currentUser else { return }
        
        // Fetch recent health metrics from Core Data
        let request = NSFetchRequest<HealthMetricEntity>(entityName: "HealthMetricEntity")
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HealthMetricEntity.timestamp, ascending: false)]
        request.fetchLimit = 20
        
        do {
            let entities = try coreDataManager.context.fetch(request)
            recentHealthMetrics = entities.compactMap { entity in
                HealthMetric(from: entity)
            }
        } catch {
            self.error = .dataLoadFailed(error.localizedDescription)
        }
    }
    
    private func updateInsights() {
        // Update insights based on recent data
        let heartRateMetrics = recentHealthMetrics.filter { $0.type == "heart_rate" }
        let bpMetrics = recentHealthMetrics.filter { $0.type.contains("bp") }
        let weightMetrics = recentHealthMetrics.filter { $0.type == "weight" }
        
        // Heart rate insights
        if !heartRateMetrics.isEmpty {
            let avgHeartRate = heartRateMetrics.reduce(0) { $0 + $1.value } / Double(heartRateMetrics.count)
            if avgHeartRate > 100 {
                heartRateInsight = "Your average heart rate is elevated. Consider consulting your doctor."
            } else if avgHeartRate < 60 {
                heartRateInsight = "Your heart rate is on the lower side. This could be normal if you're athletic."
            } else {
                heartRateInsight = "Your heart rate is within normal range. Keep up the good work!"
            }
        }
        
        // Blood pressure insights
        if !bpMetrics.isEmpty {
            let systolicReadings = bpMetrics.filter { $0.type == "systolic_bp" }
            if let lastSystolic = systolicReadings.first {
                if lastSystolic.value > 140 {
                    bloodPressureInsight = "Your blood pressure is elevated. Monitor closely and consult your doctor."
                } else if lastSystolic.value > 120 {
                    bloodPressureInsight = "Your blood pressure is slightly elevated. Consider lifestyle changes."
                } else {
                    bloodPressureInsight = "Your blood pressure is within normal range."
                }
            }
        }
        
        // Weight insights
        if weightMetrics.count >= 2 {
            let weightChange = weightMetrics[0].value - weightMetrics[1].value
            if abs(weightChange) > 2 {
                weightInsight = "Significant weight change detected. Monitor your diabetes management closely."
            } else {
                weightInsight = "Your weight is stable. Great for diabetes management!"
            }
        }
    }
}

// MARK: - Supporting Models
// HealthMetric is now defined in HealthModels.swift

// MARK: - Error Types

enum HealthError: LocalizedError {
    case healthKitNotAvailable
    case authorizationFailed(String)
    case syncFailed(String)
    case dataLoadFailed(String)
    case noCurrentUser
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .authorizationFailed(let message):
            return "HealthKit authorization failed: \(message)"
        case .syncFailed(let message):
            return "HealthKit sync failed: \(message)"
        case .dataLoadFailed(let message):
            return "Failed to load health data: \(message)"
        case .noCurrentUser:
            return "No current user found"
        }
    }
}