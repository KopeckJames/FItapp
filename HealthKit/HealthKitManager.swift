import HealthKit
import Foundation
import SwiftUI

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    
    // Health data types we want to read and write
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.workoutType(),
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        HKObjectType.workoutType()
    ]
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                authorizationError = "HealthKit is not available on this device"
            }
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run {
                isAuthorized = true
                authorizationError = nil
            }
        } catch {
            await MainActor.run {
                authorizationError = "HealthKit authorization failed: \(error.localizedDescription)"
                isAuthorized = false
            }
        }
    }
    
    func checkAuthorizationStatus() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        // Check if we have authorization for key types
        let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        let authStatus = healthStore.authorizationStatus(for: glucoseType)
        
        return authStatus == .sharingAuthorized
    }
    
    // MARK: - Glucose Data
    
    func saveGlucoseReading(level: Double, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        let glucoseUnit = HKUnit(from: "mg/dL")
        let glucoseQuantity = HKQuantity(unit: glucoseUnit, doubleValue: level)
        
        let glucoseSample = HKQuantitySample(
            type: glucoseType,
            quantity: glucoseQuantity,
            start: date,
            end: date,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "DiabfitApp": "glucose_reading"
            ]
        )
        
        try await healthStore.save(glucoseSample)
    }
    
    func fetchRecentGlucoseReadings(limit: Int = 50) async throws -> [GlucoseReading] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: glucoseType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let readings = (samples as? [HKQuantitySample])?.compactMap { sample in
                    GlucoseReading(
                        level: Int(sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))),
                        timestamp: sample.startDate,
                        notes: sample.metadata?["notes"] as? String
                    )
                } ?? []
                
                continuation.resume(returning: readings)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Heart Rate Data
    
    func saveHeartRate(_ heartRate: Double, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let heartRateQuantity = HKQuantity(unit: heartRateUnit, doubleValue: heartRate)
        
        let heartRateSample = HKQuantitySample(
            type: heartRateType,
            quantity: heartRateQuantity,
            start: date,
            end: date,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "DiabfitApp": "heart_rate"
            ]
        )
        
        try await healthStore.save(heartRateSample)
    }
    
    // MARK: - Blood Pressure Data
    
    func saveBloodPressure(systolic: Double, diastolic: Double, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        let pressureUnit = HKUnit.millimeterOfMercury()
        
        let systolicQuantity = HKQuantity(unit: pressureUnit, doubleValue: systolic)
        let diastolicQuantity = HKQuantity(unit: pressureUnit, doubleValue: diastolic)
        
        let systolicSample = HKQuantitySample(
            type: systolicType,
            quantity: systolicQuantity,
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        let diastolicSample = HKQuantitySample(
            type: diastolicType,
            quantity: diastolicQuantity,
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        try await healthStore.save([systolicSample, diastolicSample])
    }
    
    // MARK: - Weight Data
    
    func saveWeight(_ weight: Double, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let weightUnit = HKUnit.pound()
        let weightQuantity = HKQuantity(unit: weightUnit, doubleValue: weight)
        
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "DiabfitApp": "weight"
            ]
        )
        
        try await healthStore.save(weightSample)
    }
    
    // MARK: - Exercise/Workout Data
    
    func saveWorkout(type: HKWorkoutActivityType, duration: TimeInterval, calories: Double?, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        let startDate = date
        let endDate = date.addingTimeInterval(duration)
        
        try await builder.beginCollection(at: startDate)
        
        if let calories = calories {
            let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: startDate, end: endDate)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.add([energySample]) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
        
        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()
    }
    
    // MARK: - Real-time Data Monitoring
    
    func startObservingGlucoseChanges(completion: @escaping ([GlucoseReading]) -> Void) {
        guard isAuthorized else { return }
        
        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        
        let query = HKObserverQuery(sampleType: glucoseType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Observer query error: \(error)")
                return
            }
            
            Task {
                do {
                    let readings = try await self?.fetchRecentGlucoseReadings(limit: 10) ?? []
                    await MainActor.run {
                        completion(readings)
                    }
                } catch {
                    print("Failed to fetch glucose readings: \(error)")
                }
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: glucoseType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error: \(error)")
            }
        }
    }
    
    // MARK: - Data Sync
    
    func syncAllHealthData() async throws -> HealthDataSummary {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        async let glucoseReadings = fetchRecentGlucoseReadings(limit: 30)
        async let heartRateData = fetchRecentHeartRate()
        async let weightData = fetchRecentWeight()
        async let workoutData = fetchRecentWorkouts()
        
        return try await HealthDataSummary(
            glucoseReadings: glucoseReadings,
            heartRate: heartRateData,
            weight: weightData,
            workouts: workoutData
        )
    }
    
    private func fetchRecentHeartRate() async throws -> Double? {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let heartRate = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchRecentWeight() async throws -> Double? {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let weight = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .pound())
                continuation.resume(returning: weight)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchRecentWorkouts() async throws -> [WorkoutSummary] {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: 10,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts: [WorkoutSummary] = (samples as? [HKWorkout])?.map { workout in
                    // Use statistics for energy burned instead of deprecated property
                    let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
                    let energyStats = workout.statistics(for: energyType)
                    let calories = energyStats?.sumQuantity()?.doubleValue(for: .kilocalorie())
                    
                    return WorkoutSummary(
                        type: workout.workoutActivityType.name,
                        duration: workout.duration,
                        calories: calories,
                        date: workout.startDate
                    )
                } ?? []
                
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Supporting Types

enum HealthKitError: Error, LocalizedError {
    case notAuthorized
    case notAvailable
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .notAvailable:
            return "HealthKit not available on this device"
        case .saveFailed(let message):
            return "Failed to save to HealthKit: \(message)"
        }
    }
}

struct HealthDataSummary {
    let glucoseReadings: [GlucoseReading]
    let heartRate: Double?
    let weight: Double?
    let workouts: [WorkoutSummary]
}

struct WorkoutSummary {
    let type: String
    let duration: TimeInterval
    let calories: Double?
    let date: Date
}

// Extension to get readable workout names
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .walking:
            return "Walking"
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .yoga:
            return "Yoga"
        case .traditionalStrengthTraining:
            return "Strength Training"
        case .dance:
            return "Dancing"
        default:
            return "Other"
        }
    }
}

// MARK: - Glucose Models
// GlucoseReading and GlucoseStatus are defined in GlucoseModels.swift