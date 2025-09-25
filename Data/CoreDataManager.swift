import CoreData
import Foundation
import CryptoKit

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // HIPAA Compliance: Encryption key for sensitive data
    private let encryptionKey: SymmetricKey
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DiabfitDataModel")
        
        // HIPAA Compliance: Enable encryption at rest
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable file protection for HIPAA compliance
        storeDescription?.setOption(FileProtectionType.completeUntilFirstUserAuthentication as NSString, 
                                   forKey: NSPersistentStoreFileProtectionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    private init() {
        // Generate or retrieve encryption key from Keychain
        self.encryptionKey = Self.getOrCreateEncryptionKey()
    }
    
    // MARK: - HIPAA Compliance Methods
    
    private static func getOrCreateEncryptionKey() -> SymmetricKey {
        let keyData = KeychainManager.shared.getEncryptionKey() ?? {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            KeychainManager.shared.saveEncryptionKey(keyData)
            return keyData
        }()
        
        return SymmetricKey(data: keyData)
    }
    
    func encryptSensitiveData<T: Codable>(_ data: T) -> Data? {
        do {
            let jsonData = try JSONEncoder().encode(data)
            let sealedBox = try AES.GCM.seal(jsonData, using: encryptionKey)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decryptSensitiveData<T: Codable>(_ encryptedData: Data, as type: T.Type) -> T? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            return try JSONDecoder().decode(type, from: decryptedData)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Core Data Operations
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    // MARK: - User Management
    
    func createUser(email: String, name: String, dateOfBirth: Date? = nil) -> UserEntity {
        let user = UserEntity(context: context)
        user.email = email
        user.name = name
        user.dateOfBirth = dateOfBirth
        user.createdAt = Date()
        
        save()
        return user
    }
    
    func getCurrentUser() -> UserEntity? {
        let request = NSFetchRequest<UserEntity>(entityName: "UserEntity")
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch user: \(error)")
            return nil
        }
    }
    
    // MARK: - Glucose Readings
    
    func saveGlucoseReading(level: Int, timestamp: Date, notes: String?, for user: UserEntity) {
        let reading = GlucoseReadingEntity(context: context)
        reading.level = Int32(level)
        reading.timestamp = timestamp
        reading.notes = notes
        reading.user = user
        
        save()
        
        // Trigger analytics update
        AnalyticsEngine.shared.updateGlucosePatterns(for: user)
    }
    
    func fetchGlucoseReadings(for user: UserEntity, limit: Int = 50) -> [GlucoseReadingEntity] {
        let request = NSFetchRequest<GlucoseReadingEntity>(entityName: "GlucoseReadingEntity")
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReadingEntity.timestamp, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch glucose readings: \(error)")
            return []
        }
    }
    
    // MARK: - Health Metrics
    
    func saveHealthMetric(systolicBP: Int?, diastolicBP: Int?, heartRate: Int?, 
                         weight: Double?, temperature: Double?, timestamp: Date, for user: UserEntity) {
        let metric = HealthMetricEntity(context: context)
        // Store different health metrics as separate entries
        if let systolicBP = systolicBP {
            let bpMetric = HealthMetricEntity(context: context)
            bpMetric.type = "systolic_bp"
            bpMetric.value = Double(systolicBP)
            bpMetric.unit = "mmHg"
            bpMetric.timestamp = timestamp
            bpMetric.user = user
        }
        
        if let diastolicBP = diastolicBP {
            let bpMetric = HealthMetricEntity(context: context)
            bpMetric.type = "diastolic_bp"
            bpMetric.value = Double(diastolicBP)
            bpMetric.unit = "mmHg"
            bpMetric.timestamp = timestamp
            bpMetric.user = user
        }
        
        if let heartRate = heartRate {
            let hrMetric = HealthMetricEntity(context: context)
            hrMetric.type = "heart_rate"
            hrMetric.value = Double(heartRate)
            hrMetric.unit = "bpm"
            hrMetric.timestamp = timestamp
            hrMetric.user = user
        }
        
        if let weight = weight {
            let weightMetric = HealthMetricEntity(context: context)
            weightMetric.type = "weight"
            weightMetric.value = weight
            weightMetric.unit = "lbs"
            weightMetric.timestamp = timestamp
            weightMetric.user = user
        }
        
        if let temperature = temperature {
            let tempMetric = HealthMetricEntity(context: context)
            tempMetric.type = "temperature"
            tempMetric.value = temperature
            tempMetric.unit = "F"
            tempMetric.timestamp = timestamp
            tempMetric.user = user
        }
        
        save()
        
        // Trigger analytics update
        AnalyticsEngine.shared.updateHealthPatterns(for: user)
    }
    
    // MARK: - Exercise Logging
    
    func saveExercise(type: String, duration: Int, intensity: String, 
                     timestamp: Date, notes: String?, for user: UserEntity) {
        let exercise = ExerciseEntity(context: context)
        exercise.type = type
        exercise.duration = Double(duration)
        exercise.calories = 0 // Default value, could be calculated
        exercise.timestamp = timestamp
        exercise.notes = notes
        exercise.user = user
        
        save()
        
        // Trigger analytics update
        AnalyticsEngine.shared.updateExercisePatterns(for: user)
    }
    
    // MARK: - Meal Logging
    
    func saveMeal(name: String, mealType: String, carbs: Double, protein: Double, 
                 calories: Int, timestamp: Date, notes: String?, for user: UserEntity) {
        let meal = MealEntity(context: context)
        meal.name = name
        meal.carbs = carbs
        meal.protein = protein
        meal.calories = Int32(calories)
        meal.timestamp = timestamp
        meal.notes = notes
        meal.user = user
        
        save()
        
        // Trigger analytics update
        AnalyticsEngine.shared.updateNutritionPatterns(for: user)
    }
    
    // MARK: - Medication Management
    // Medication-specific methods are handled in MedicationService to avoid circular dependencies

    // MARK: - Analytics Data Retrieval
    
    func getGlucoseAnalyticsData(for user: UserEntity, days: Int = 30) -> [GlucoseReadingEntity] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let request = NSFetchRequest<GlucoseReadingEntity>(entityName: "GlucoseReadingEntity")
        request.predicate = NSPredicate(format: "user == %@ AND timestamp >= %@", user, startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReadingEntity.timestamp, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch analytics data: \(error)")
            return []
        }
    }
    
    func getCorrelationData(for user: UserEntity, days: Int = 30) -> CorrelationData {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Fetch all related data for correlation analysis
        let glucoseReadings = getGlucoseAnalyticsData(for: user, days: days)
        
        let exerciseRequest = NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
        exerciseRequest.predicate = NSPredicate(format: "user == %@ AND timestamp >= %@", user, startDate as NSDate)
        
        let mealRequest = NSFetchRequest<MealEntity>(entityName: "MealEntity")
        mealRequest.predicate = NSPredicate(format: "user == %@ AND timestamp >= %@", user, startDate as NSDate)
        
        do {
            let exercises = try context.fetch(exerciseRequest)
            let meals = try context.fetch(mealRequest)
            
            return CorrelationData(
                glucoseReadings: glucoseReadings,
                exercises: exercises,
                meals: meals
            )
        } catch {
            print("Failed to fetch correlation data: \(error)")
            return CorrelationData(glucoseReadings: [], exercises: [], meals: [])
        }
    }
}

// MARK: - Supporting Data Structures

struct CorrelationData {
    let glucoseReadings: [GlucoseReadingEntity]
    let exercises: [ExerciseEntity]
    let meals: [MealEntity]
}

// MARK: - HIPAA Compliance Extensions

extension CoreDataManager {
    func auditDataAccess(action: String, entityType: String, userId: UUID) {
        // Log data access for HIPAA compliance
        let auditLog = """
        AUDIT LOG:
        Timestamp: \(Date())
        Action: \(action)
        Entity: \(entityType)
        User ID: \(userId)
        """
        
        // In production, this would be sent to a secure audit logging service
        print("HIPAA Audit: \(auditLog)")
    }
    
    func anonymizeUserData(for user: UserEntity) {
        // HIPAA Right to be forgotten - anonymize data
        user.email = "anonymized@example.com"
        user.name = "Anonymized User"
        // Clear sensitive data (simplified implementation)
        
        save()
    }
    
    func exportUserData(for user: UserEntity) -> Data? {
        // HIPAA Right to data portability
        let glucoseReadings = fetchGlucoseReadings(for: user)
        
        // Fetch exercises for the user
        let exerciseRequest = NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
        exerciseRequest.predicate = NSPredicate(format: "user == %@", user)
        let exercises = (try? context.fetch(exerciseRequest)) ?? []
        
        // Fetch meals for the user
        let mealRequest = NSFetchRequest<MealEntity>(entityName: "MealEntity")
        mealRequest.predicate = NSPredicate(format: "user == %@", user)
        let meals = (try? context.fetch(mealRequest)) ?? []
        
        // Fetch health metrics for the user
        let healthMetricRequest = NSFetchRequest<HealthMetricEntity>(entityName: "HealthMetricEntity")
        healthMetricRequest.predicate = NSPredicate(format: "user == %@", user)
        let healthMetrics = (try? context.fetch(healthMetricRequest)) ?? []
        
        let exportData = UserDataExport(
            user: ExportableUser(from: user),
            glucoseReadings: glucoseReadings.map { ExportableGlucoseReading(from: $0) },
            exercises: exercises.map { ExportableExercise(from: $0) },
            meals: meals.map { ExportableMeal(from: $0) },
            healthMetrics: healthMetrics.map { ExportableHealthMetric(from: $0) }
        )
        
        return encryptSensitiveData(exportData)
    }
}

struct UserDataExport: Codable {
    let user: ExportableUser
    let glucoseReadings: [ExportableGlucoseReading]
    let exercises: [ExportableExercise]
    let meals: [ExportableMeal]
    let healthMetrics: [ExportableHealthMetric]
}

// MARK: - Codable Export Models
struct ExportableUser: Codable {
    let email: String?
    let name: String?
    let dateOfBirth: Date?
    let createdAt: Date?
    
    init(from entity: UserEntity) {
        self.email = entity.email
        self.name = entity.name
        self.dateOfBirth = entity.dateOfBirth
        self.createdAt = entity.createdAt
    }
}

struct ExportableGlucoseReading: Codable {
    let level: Int32
    let timestamp: Date?
    let notes: String?
    
    init(from entity: GlucoseReadingEntity) {
        self.level = entity.level
        self.timestamp = entity.timestamp
        self.notes = entity.notes
    }
}

struct ExportableExercise: Codable {
    let type: String?
    let duration: Double
    let calories: Double
    let timestamp: Date?
    let notes: String?
    
    init(from entity: ExerciseEntity) {
        self.type = entity.type
        self.duration = entity.duration
        self.calories = entity.calories
        self.timestamp = entity.timestamp
        self.notes = entity.notes
    }
}

struct ExportableMeal: Codable {
    let name: String?
    let carbs: Double
    let protein: Double
    let calories: Int32
    let timestamp: Date?
    let notes: String?
    
    init(from entity: MealEntity) {
        self.name = entity.name
        self.carbs = entity.carbs
        self.protein = entity.protein
        self.calories = entity.calories
        self.timestamp = entity.timestamp
        self.notes = entity.notes
    }
}

struct ExportableHealthMetric: Codable {
    let type: String?
    let value: Double
    let unit: String?
    let timestamp: Date?
    
    init(from entity: HealthMetricEntity) {
        self.type = entity.type
        self.value = entity.value
        self.unit = entity.unit
        self.timestamp = entity.timestamp
    }
}