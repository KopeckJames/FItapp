import Foundation
import SwiftUI

// MARK: - Medication Models

struct Medication: Identifiable, Codable {
    let id: UUID
    let name: String
    let dosage: String
    let frequency: MedicationFrequency
    let medicationType: MedicationType
    let prescribedBy: String?
    let startDate: Date
    let endDate: Date?
    let instructions: String?
    let sideEffects: [String]
    let isActive: Bool
    let reminderEnabled: Bool
    let reminderTimes: [Date]
    let color: MedicationColor
    let shape: MedicationShape
    
    init(
        name: String,
        dosage: String,
        frequency: MedicationFrequency,
        medicationType: MedicationType,
        prescribedBy: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        instructions: String? = nil,
        sideEffects: [String] = [],
        isActive: Bool = true,
        reminderEnabled: Bool = true,
        reminderTimes: [Date] = [],
        color: MedicationColor = .blue,
        shape: MedicationShape = .round
    ) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.medicationType = medicationType
        self.prescribedBy = prescribedBy
        self.startDate = startDate
        self.endDate = endDate
        self.instructions = instructions
        self.sideEffects = sideEffects
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.reminderTimes = reminderTimes
        self.color = color
        self.shape = shape
    }
    
    var nextDoseTime: Date? {
        guard isActive && reminderEnabled else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Find next reminder time today or tomorrow
        for time in reminderTimes.sorted(by: { $0 < $1 }) {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            if let hour = components.hour, let minute = components.minute,
               let todayTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) {
                if todayTime > now {
                    return todayTime
                }
            }
        }
        
        // If no more times today, get first time tomorrow
        if let firstTime = reminderTimes.min(),
           let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let components = calendar.dateComponents([.hour, .minute], from: firstTime)
            if let hour = components.hour, let minute = components.minute,
               let tomorrowTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow) {
                return tomorrowTime
            }
        }
        
        return nil
    }
    
    var isOverdue: Bool {
        guard let nextDose = nextDoseTime else { return false }
        return nextDose < Date()
    }
}

enum MedicationFrequency: String, CaseIterable, Codable {
    case onceDaily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case threeTimesDaily = "Three Times Daily"
    case fourTimesDaily = "Four Times Daily"
    case everyOtherDay = "Every Other Day"
    case weekly = "Weekly"
    case asNeeded = "As Needed"
    case custom = "Custom"
    
    var defaultTimes: [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .onceDaily:
            return [calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now]
        case .twiceDaily:
            return [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
            ]
        case .threeTimesDaily:
            return [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
            ]
        case .fourTimesDaily:
            return [
                calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
            ]
        default:
            return [calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now]
        }
    }
    
    var icon: String {
        switch self {
        case .onceDaily: return "1.circle.fill"
        case .twiceDaily: return "2.circle.fill"
        case .threeTimesDaily: return "3.circle.fill"
        case .fourTimesDaily: return "4.circle.fill"
        case .everyOtherDay: return "calendar.badge.clock"
        case .weekly: return "calendar.badge.plus"
        case .asNeeded: return "questionmark.circle.fill"
        case .custom: return "gear.circle.fill"
        }
    }
}

enum MedicationType: String, CaseIterable, Codable {
    case insulin = "Insulin"
    case metformin = "Metformin"
    case bloodPressure = "Blood Pressure"
    case cholesterol = "Cholesterol"
    case supplement = "Supplement"
    case vitamin = "Vitamin"
    case antibiotic = "Antibiotic"
    case painRelief = "Pain Relief"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .insulin: return "syringe.fill"
        case .metformin: return "pills.fill"
        case .bloodPressure: return "heart.fill"
        case .cholesterol: return "drop.fill"
        case .supplement: return "leaf.fill"
        case .vitamin: return "sun.max.fill"
        case .antibiotic: return "cross.fill"
        case .painRelief: return "bandage.fill"
        case .other: return "pill.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .insulin: return .orange
        case .metformin: return .blue
        case .bloodPressure: return .red
        case .cholesterol: return .purple
        case .supplement: return .green
        case .vitamin: return .yellow
        case .antibiotic: return .pink
        case .painRelief: return .indigo
        case .other: return .gray
        }
    }
}

enum MedicationColor: String, CaseIterable, Codable {
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case yellow = "Yellow"
    case orange = "Orange"
    case purple = "Purple"
    case pink = "Pink"
    case white = "White"
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .white: return .white
        }
    }
}

enum MedicationShape: String, CaseIterable, Codable {
    case round = "Round"
    case oval = "Oval"
    case square = "Square"
    case capsule = "Capsule"
    
    var icon: String {
        switch self {
        case .round: return "circle.fill"
        case .oval: return "oval.fill"
        case .square: return "square.fill"
        case .capsule: return "capsule.fill"
        }
    }
}

// MARK: - Medication Dose Models

struct MedicationDose: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    let scheduledTime: Date
    let actualTime: Date?
    let status: DoseStatus
    let notes: String?
    let sideEffectsExperienced: [String]
    let skippedReason: String?
    
    init(
        medicationId: UUID,
        scheduledTime: Date,
        actualTime: Date? = nil,
        status: DoseStatus = .pending,
        notes: String? = nil,
        sideEffectsExperienced: [String] = [],
        skippedReason: String? = nil
    ) {
        self.id = UUID()
        self.medicationId = medicationId
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.status = status
        self.notes = notes
        self.sideEffectsExperienced = sideEffectsExperienced
        self.skippedReason = skippedReason
    }
    
    var isOverdue: Bool {
        status == .pending && scheduledTime < Date()
    }
    
    var adherenceScore: Double {
        switch status {
        case .taken: return 1.0
        case .skipped: return 0.0
        case .pending: return isOverdue ? 0.0 : 1.0
        }
    }
}

enum DoseStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case taken = "Taken"
    case skipped = "Skipped"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .taken: return .green
        case .skipped: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .taken: return "checkmark.circle.fill"
        case .skipped: return "xmark.circle.fill"
        }
    }
}

// MARK: - Adherence Models

struct AdherenceReport: Codable {
    let medicationId: UUID
    let period: AdherencePeriod
    let startDate: Date
    let endDate: Date
    let totalDoses: Int
    let takenDoses: Int
    let skippedDoses: Int
    let adherencePercentage: Double
    let streak: Int
    let longestStreak: Int
    
    init(medicationId: UUID, period: AdherencePeriod, doses: [MedicationDose]) {
        self.medicationId = medicationId
        self.period = period
        
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .week:
            self.startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            self.endDate = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        case .month:
            self.startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
            self.endDate = calendar.dateInterval(of: .month, for: now)?.end ?? now
        case .threeMonths:
            self.startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            self.endDate = now
        case .year:
            self.startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
            self.endDate = calendar.dateInterval(of: .year, for: now)?.end ?? now
        }
        
        let periodDoses = doses.filter { dose in
            dose.scheduledTime >= startDate && dose.scheduledTime <= endDate
        }
        
        self.totalDoses = periodDoses.count
        self.takenDoses = periodDoses.filter { $0.status == .taken }.count
        self.skippedDoses = periodDoses.filter { $0.status == .skipped }.count
        self.adherencePercentage = totalDoses > 0 ? Double(takenDoses) / Double(totalDoses) * 100 : 0
        
        // Calculate current streak
        let sortedDoses = periodDoses.sorted { $0.scheduledTime > $1.scheduledTime }
        var currentStreak = 0
        var maxStreak = 0
        var tempStreak = 0
        
        for dose in sortedDoses {
            if dose.status == .taken {
                tempStreak += 1
                if currentStreak == 0 {
                    currentStreak = tempStreak
                }
            } else {
                maxStreak = max(maxStreak, tempStreak)
                tempStreak = 0
            }
        }
        
        self.streak = currentStreak
        self.longestStreak = max(maxStreak, tempStreak)
    }
}

enum AdherencePeriod: String, CaseIterable, Codable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    
    var icon: String {
        switch self {
        case .week: return "calendar"
        case .month: return "calendar.badge.clock"
        case .threeMonths: return "calendar.badge.plus"
        case .year: return "calendar.circle.fill"
        }
    }
}

// MARK: - Calendar Models

struct MedicationCalendarDay: Identifiable {
    let id: UUID
    let date: Date
    let doses: [MedicationDose]
    
    var adherenceScore: Double {
        guard !doses.isEmpty else { return 1.0 }
        let totalScore = doses.reduce(0.0) { $0 + $1.adherenceScore }
        return totalScore / Double(doses.count)
    }
    
    var hasOverdueDoses: Bool {
        doses.contains { $0.isOverdue }
    }
    
    var completedDoses: Int {
        doses.filter { $0.status == .taken }.count
    }
    
    var totalDoses: Int {
        doses.count
    }
    
    init(date: Date, doses: [MedicationDose]) {
        self.id = UUID()
        self.date = date
        self.doses = doses
    }
}

// MARK: - Notification Models

struct MedicationReminder: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    let scheduledTime: Date
    let isEnabled: Bool
    let notificationId: String
    
    init(medicationId: UUID, scheduledTime: Date, isEnabled: Bool = true) {
        self.id = UUID()
        self.medicationId = medicationId
        self.scheduledTime = scheduledTime
        self.isEnabled = isEnabled
        self.notificationId = "medication_\(medicationId.uuidString)_\(scheduledTime.timeIntervalSince1970)"
    }
}