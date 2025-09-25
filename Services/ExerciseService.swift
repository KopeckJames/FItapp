import Foundation
import HealthKit
import Combine

@MainActor
class ExerciseService: ObservableObject {
    @Published var isHealthKitAuthorized = false
    @Published var recentWorkouts: [Workout] = []
    @Published var todaysWorkoutCount = 0
    @Published var todaysTotalMinutes = 0
    @Published var todaysTotalCalories = 0
    @Published var weeklyMinutes = 0
    @Published var weeklyGoal = 150 // WHO recommendation: 150 minutes per week
    @Published var weeklyProgressInsight = "Start exercising to see your progress"
    @Published var diabetesBenefitsInsight = "Regular exercise helps control blood sugar levels"
    @Published var recommendationsInsight = "Aim for 150 minutes of moderate exercise per week"
    @Published var isLoading = false
    @Published var error: ExerciseError?
    
    private let healthStore = HKHealthStore()
    private let coreDataManager = CoreDataManager.shared
    private var currentUser: UserEntity?
    
    init() {
        self.currentUser = coreDataManager.getCurrentUser()
        checkHealthKitAuthorization()
        loadRecentWorkouts()
        calculateTodaysActivity()
        calculateWeeklyActivity()
        updateInsights()
    }
    
    // MARK: - HealthKit Authorization
    
    func requestHealthKitPermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.error = .healthKitNotAvailable
            }
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let typesToRead: Set<HKObjectType> = [workoutType, activeEnergyType]
        let typesToWrite: Set<HKSampleType> = [workoutType, activeEnergyType]
        
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
    
    // MARK: - Exercise Management
    
    func saveExercise(
        type: String,
        duration: Int,
        intensity: String,
        calories: Int = 0,
        notes: String? = nil,
        timestamp: Date = Date()
    ) async throws {
        guard let user = currentUser else {
            throw ExerciseError.noCurrentUser
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Save to Core Data
        coreDataManager.saveExercise(
            type: type,
            duration: duration,
            intensity: intensity,
            timestamp: timestamp,
            notes: notes,
            for: user
        )
        
        // Save to HealthKit if authorized
        if isHealthKitAuthorized {
            try await saveWorkoutToHealthKit(
                type: type,
                duration: duration,
                calories: calories,
                timestamp: timestamp
            )
        }
        
        // Reload data
        loadRecentWorkouts()
        calculateTodaysActivity()
        calculateWeeklyActivity()
        updateInsights()
    }
    
    private func saveWorkoutToHealthKit(
        type: String,
        duration: Int,
        calories: Int,
        timestamp: Date
    ) async throws {
        let workoutType = mapExerciseTypeToHealthKit(type)
        let startDate = timestamp
        let endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate) ?? startDate
        
        var samples: [HKSample] = []
        
        // Create workout
        let workout = HKWorkout(
            activityType: workoutType,
            start: startDate,
            end: endDate,
            duration: TimeInterval(duration * 60),
            totalEnergyBurned: calories > 0 ? HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories)) : nil,
            totalDistance: nil,
            metadata: [HKMetadataKeyExternalUUID: UUID().uuidString]
        )
        
        samples.append(workout)
        
        // Add energy burned sample if calories provided
        if calories > 0 {
            let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: energyQuantity,
                start: startDate,
                end: endDate
            )
            samples.append(energySample)
        }
        
        try await healthStore.save(samples)
    }
    
    private func mapExerciseTypeToHealthKit(_ type: String) -> HKWorkoutActivityType {
        switch type.lowercased() {
        case "walking": return .walking
        case "running": return .running
        case "cycling": return .cycling
        case "swimming": return .swimming
        case "strength training": return .functionalStrengthTraining
        case "yoga": return .yoga
        case "dancing": return .dance
        case "hiking": return .hiking
        case "tennis": return .tennis
        case "basketball": return .basketball
        case "soccer": return .soccer
        default: return .other
        }
    }
    
    func syncFromHealthKit() async {
        guard isHealthKitAuthorized else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            await syncWorkoutData()
            loadRecentWorkouts()
            calculateTodaysActivity()
            calculateWeeklyActivity()
            updateInsights()
        } catch {
            await MainActor.run {
                self.error = .syncFailed(error.localizedDescription)
            }
        }
    }
    
    private func syncWorkoutData() async {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
            end: Date()
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 100,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let workouts = samples as? [HKWorkout] {
                    // Process and save workout samples
                    for workout in workouts {
                        let type = self.mapHealthKitTypeToString(workout.workoutActivityType)
                        let duration = Int(workout.duration / 60) // Convert to minutes
                        let calories = Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
                        
                        // Save to Core Data if not already exists
                        // Implementation would check for duplicates
                    }
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }
    
    private func mapHealthKitTypeToString(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .functionalStrengthTraining: return "Strength Training"
        case .yoga: return "Yoga"
        case .dance: return "Dancing"
        case .hiking: return "Hiking"
        case .tennis: return "Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        default: return "Other"
        }
    }
    
    // MARK: - Data Loading and Calculations
    
    private func loadRecentWorkouts() {
        guard let user = currentUser else { return }
        
        let request = NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseEntity.timestamp, ascending: false)]
        request.fetchLimit = 20
        
        do {
            let entities = try coreDataManager.context.fetch(request)
            recentWorkouts = entities.compactMap { entity in
                Workout(from: entity)
            }
        } catch {
            self.error = .dataLoadFailed(error.localizedDescription)
        }
    }
    
    private func calculateTodaysActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let todaysWorkouts = recentWorkouts.filter { workout in
            workout.timestamp >= today && workout.timestamp < tomorrow
        }
        
        todaysWorkoutCount = todaysWorkouts.count
        todaysTotalMinutes = todaysWorkouts.reduce(0) { $0 + $1.duration }
        todaysTotalCalories = todaysWorkouts.reduce(0) { $0 + $1.calories }
    }
    
    private func calculateWeeklyActivity() {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let weeklyWorkouts = recentWorkouts.filter { workout in
            workout.timestamp >= weekStart
        }
        
        weeklyMinutes = weeklyWorkouts.reduce(0) { $0 + $1.duration }
    }
    
    private func updateInsights() {
        // Weekly progress insight
        let progressPercentage = Double(weeklyMinutes) / Double(weeklyGoal) * 100
        if progressPercentage >= 100 {
            weeklyProgressInsight = "Excellent! You've exceeded your weekly exercise goal."
        } else if progressPercentage >= 75 {
            weeklyProgressInsight = "Great progress! You're almost at your weekly goal."
        } else if progressPercentage >= 50 {
            weeklyProgressInsight = "Good start! Keep going to reach your weekly goal."
        } else if progressPercentage > 0 {
            weeklyProgressInsight = "You've started exercising this week. Keep it up!"
        } else {
            weeklyProgressInsight = "Start exercising to see your weekly progress."
        }
        
        // Diabetes benefits insight
        if weeklyMinutes >= 150 {
            diabetesBenefitsInsight = "Excellent! Regular exercise helps improve insulin sensitivity and blood sugar control."
        } else if weeklyMinutes >= 75 {
            diabetesBenefitsInsight = "Good exercise routine! This helps with glucose metabolism and cardiovascular health."
        } else if weeklyMinutes > 0 {
            diabetesBenefitsInsight = "Any exercise is beneficial for diabetes management. Try to increase gradually."
        } else {
            diabetesBenefitsInsight = "Regular exercise is crucial for diabetes management. Start with light activities."
        }
        
        // Recommendations insight
        let remainingMinutes = max(0, weeklyGoal - weeklyMinutes)
        if remainingMinutes == 0 {
            recommendationsInsight = "You've met your weekly goal! Consider adding strength training twice a week."
        } else if remainingMinutes <= 30 {
            recommendationsInsight = "Just \(remainingMinutes) more minutes to reach your weekly goal!"
        } else {
            let sessionsNeeded = Int(ceil(Double(remainingMinutes) / 30.0))
            recommendationsInsight = "Try \(sessionsNeeded) more 30-minute sessions this week to reach your goal."
        }
    }
}

// MARK: - Supporting Models
// Workout model is now defined in ExerciseModels.swift

// MARK: - Error Types

enum ExerciseError: LocalizedError {
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
            return "Failed to load exercise data: \(message)"
        case .noCurrentUser:
            return "No current user found"
        }
    }
}