import Foundation
import CoreData

// MARK: - Core Data Entity Placeholders
// These are simplified placeholder entities for compilation
// In a real app, these would be generated from the .xcdatamodeld file

@objc(UserEntity)
public class UserEntity: NSManagedObject {
    @NSManaged public var email: String
    @NSManaged public var name: String
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var createdAt: Date
}

@objc(GlucoseReadingEntity)
public class GlucoseReadingEntity: NSManagedObject {
    @NSManaged public var level: Int32
    @NSManaged public var timestamp: Date?
    @NSManaged public var notes: String?
    @NSManaged public var user: UserEntity?
}

@objc(ExerciseEntity)
public class ExerciseEntity: NSManagedObject {
    @NSManaged public var type: String
    @NSManaged public var duration: Double
    @NSManaged public var calories: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var notes: String?
    @NSManaged public var user: UserEntity?
}

@objc(MealEntity)
public class MealEntity: NSManagedObject {
    @NSManaged public var name: String
    @NSManaged public var carbs: Double
    @NSManaged public var protein: Double
    @NSManaged public var calories: Int32
    @NSManaged public var timestamp: Date?
    @NSManaged public var notes: String?
    @NSManaged public var user: UserEntity?
}

@objc(HealthMetricEntity)
public class HealthMetricEntity: NSManagedObject {
    @NSManaged public var type: String
    @NSManaged public var value: Double
    @NSManaged public var unit: String
    @NSManaged public var timestamp: Date?
    @NSManaged public var user: UserEntity?
}

@objc(MedicationEntity)
public class MedicationEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dosage: String
    @NSManaged public var frequency: String
    @NSManaged public var medicationType: String
    @NSManaged public var prescribedBy: String?
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var instructions: String?
    @NSManaged public var sideEffects: Data? // JSON encoded array
    @NSManaged public var isActive: Bool
    @NSManaged public var reminderEnabled: Bool
    @NSManaged public var reminderTimes: Data? // JSON encoded array
    @NSManaged public var color: String
    @NSManaged public var shape: String
    @NSManaged public var user: UserEntity?
    @NSManaged public var doses: NSSet?
}

@objc(MedicationDoseEntity)
public class MedicationDoseEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var medicationId: UUID
    @NSManaged public var scheduledTime: Date
    @NSManaged public var actualTime: Date?
    @NSManaged public var status: String
    @NSManaged public var notes: String?
    @NSManaged public var sideEffectsExperienced: Data? // JSON encoded array
    @NSManaged public var skippedReason: String?
    @NSManaged public var medication: MedicationEntity?
    @NSManaged public var user: UserEntity?
}

@objc(MedicationReminderEntity)
public class MedicationReminderEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var medicationId: UUID
    @NSManaged public var scheduledTime: Date
    @NSManaged public var isEnabled: Bool
    @NSManaged public var notificationId: String
    @NSManaged public var medication: MedicationEntity?
}

// MARK: - Core Data Relationships
extension MedicationEntity {
    @objc(addDosesObject:)
    @NSManaged public func addToDoses(_ value: MedicationDoseEntity)
    
    @objc(removeDosesObject:)
    @NSManaged public func removeFromDoses(_ value: MedicationDoseEntity)
    
    @objc(addDoses:)
    @NSManaged public func addToDoses(_ values: NSSet)
    
    @objc(removeDoses:)
    @NSManaged public func removeFromDoses(_ values: NSSet)
}

// MARK: - Placeholder Extensions
// In a real app, these entities would be generated from Core Data model
// and would have proper Codable implementations if needed