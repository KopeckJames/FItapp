import Foundation
import CoreData
import UserNotifications
import Combine

@MainActor
class MedicationService: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var todaysDoses: [MedicationDose] = []
    @Published var upcomingDoses: [MedicationDose] = []
    @Published var adherenceReports: [UUID: AdherenceReport] = [:]
    @Published var isLoading = false
    @Published var error: MedicationError?
    
    private let coreDataManager: CoreDataManager
    private let notificationManager: MedicationNotificationManager
    private var cancellables = Set<AnyCancellable>()
    private var currentUser: UserEntity?
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        self.notificationManager = MedicationNotificationManager()
        self.currentUser = coreDataManager.getCurrentUser()
        
        setupNotificationHandling()
        loadMedications()
        generateTodaysDoses()
    }
    
    // MARK: - Medication Management
    
    func addMedication(_ medication: Medication) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await saveMedicationToCore(medication)
            medications.append(medication)
            
            if medication.reminderEnabled {
                try await scheduleReminders(for: medication)
            }
            
            generateDosesForMedication(medication)
            generateTodaysDoses()
            
        } catch {
            self.error = .saveFailed(error.localizedDescription)
            throw error
        }
    }
    
    func updateMedication(_ medication: Medication) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await saveMedicationToCore(medication)
            
            if let index = medications.firstIndex(where: { $0.id == medication.id }) {
                medications[index] = medication
            }
            
            // Update reminders
            await notificationManager.cancelReminders(for: medication.id)
            if medication.reminderEnabled {
                try await scheduleReminders(for: medication)
            }
            
            generateTodaysDoses()
            
        } catch {
            self.error = .updateFailed(error.localizedDescription)
            throw error
        }
    }
    
    func deleteMedication(_ medication: Medication) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await deleteMedicationFromCore(medication.id)
            medications.removeAll { $0.id == medication.id }
            
            await notificationManager.cancelReminders(for: medication.id)
            generateTodaysDoses()
            
        } catch {
            self.error = .deleteFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Dose Management
    
    func markDoseTaken(_ dose: MedicationDose, at time: Date = Date(), notes: String? = nil) async throws {
        let updatedDose = MedicationDose(
            medicationId: dose.medicationId,
            scheduledTime: dose.scheduledTime,
            actualTime: time,
            status: .taken,
            notes: notes,
            sideEffectsExperienced: dose.sideEffectsExperienced,
            skippedReason: nil
        )
        
        try await saveDoseToCore(updatedDose)
        updateDoseInArrays(updatedDose)
        
        // Cancel notification for this dose
        await notificationManager.cancelDoseNotification(dose.id)
        
        // Update adherence reports
        updateAdherenceReports()
    }
    
    func markDoseSkipped(_ dose: MedicationDose, reason: String? = nil) async throws {
        let updatedDose = MedicationDose(
            medicationId: dose.medicationId,
            scheduledTime: dose.scheduledTime,
            actualTime: nil,
            status: .skipped,
            notes: dose.notes,
            sideEffectsExperienced: dose.sideEffectsExperienced,
            skippedReason: reason
        )
        
        try await saveDoseToCore(updatedDose)
        updateDoseInArrays(updatedDose)
        
        // Cancel notification for this dose
        await notificationManager.cancelDoseNotification(dose.id)
        
        // Update adherence reports
        updateAdherenceReports()
    }
    
    func snoozeReminder(_ dose: MedicationDose, minutes: Int = 15) async throws {
        let snoozeTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        await notificationManager.cancelDoseNotification(dose.id)
        try await notificationManager.scheduleSnoozeReminder(for: dose, at: snoozeTime)
    }
    
    // MARK: - Calendar and Adherence
    
    func getCalendarDays(for month: Date) -> [MedicationCalendarDay] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        
        var days: [MedicationCalendarDay] = []
        var currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            let dayDoses = getAllDoses().filter { dose in
                calendar.isDate(dose.scheduledTime, inSameDayAs: currentDate)
            }
            
            days.append(MedicationCalendarDay(date: currentDate, doses: dayDoses))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? monthInterval.end
        }
        
        return days
    }
    
    func getAdherenceReport(for medicationId: UUID, period: AdherencePeriod) -> AdherenceReport {
        let doses = getAllDoses().filter { $0.medicationId == medicationId }
        return AdherenceReport(medicationId: medicationId, period: period, doses: doses)
    }
    
    func getOverallAdherence(for period: AdherencePeriod) -> Double {
        let allDoses = getAllDoses()
        guard !allDoses.isEmpty else { return 100.0 }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
        }
        
        let periodDoses = allDoses.filter { $0.scheduledTime >= startDate }
        guard !periodDoses.isEmpty else { return 100.0 }
        
        let takenDoses = periodDoses.filter { $0.status == .taken }.count
        return Double(takenDoses) / Double(periodDoses.count) * 100
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationHandling() {
        notificationManager.doseActionPublisher
            .sink { [weak self] action in
                Task { @MainActor in
                    await self?.handleNotificationAction(action)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleNotificationAction(_ action: DoseNotificationAction) async {
        guard let dose = findDose(by: action.doseId) else { return }
        
        switch action.type {
        case .taken:
            try? await markDoseTaken(dose)
        case .skipped:
            try? await markDoseSkipped(dose, reason: "Skipped from notification")
        case .snooze:
            try? await snoozeReminder(dose)
        }
    }
    
    private func loadMedications() {
        Task {
            do {
                medications = try await loadMedicationsFromCore()
                generateTodaysDoses()
                updateAdherenceReports()
            } catch {
                self.error = .loadFailed(error.localizedDescription)
            }
        }
    }
    
    private func generateTodaysDoses() {
        let calendar = Calendar.current
        let today = Date()
        
        todaysDoses = []
        upcomingDoses = []
        
        for medication in medications.filter({ $0.isActive }) {
            let doses = generateDosesForDate(medication: medication, date: today)
            todaysDoses.append(contentsOf: doses)
            
            // Generate upcoming doses for next 7 days
            for i in 1...7 {
                if let futureDate = calendar.date(byAdding: .day, value: i, to: today) {
                    let futureDoses = generateDosesForDate(medication: medication, date: futureDate)
                    upcomingDoses.append(contentsOf: futureDoses)
                }
            }
        }
        
        todaysDoses.sort { $0.scheduledTime < $1.scheduledTime }
        upcomingDoses.sort { $0.scheduledTime < $1.scheduledTime }
    }
    
    private func generateDosesForDate(medication: Medication, date: Date) -> [MedicationDose] {
        let calendar = Calendar.current
        var doses: [MedicationDose] = []
        
        for reminderTime in medication.reminderTimes {
            if let scheduledTime = calendar.dateBySettingTimeOf(reminderTime, to: date) {
                // Check if dose already exists
                let existingDose = getAllDoses().first { dose in
                    dose.medicationId == medication.id &&
                    calendar.isDate(dose.scheduledTime, equalTo: scheduledTime, toGranularity: .minute)
                }
                
                if existingDose == nil {
                    let dose = MedicationDose(
                        medicationId: medication.id,
                        scheduledTime: scheduledTime
                    )
                    doses.append(dose)
                }
            }
        }
        
        return doses
    }
    
    private func generateDosesForMedication(_ medication: Medication) {
        let calendar = Calendar.current
        let startDate = medication.startDate
        let endDate = medication.endDate ?? calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        
        var currentDate = startDate
        while currentDate <= endDate {
            let doses = generateDosesForDate(medication: medication, date: currentDate)
            for dose in doses {
                Task {
                    try? await saveDoseToCore(dose)
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
    }
    
    private func scheduleReminders(for medication: Medication) async throws {
        try await notificationManager.scheduleReminders(for: medication)
    }
    
    private func updateDoseInArrays(_ dose: MedicationDose) {
        // Update in today's doses
        if let index = todaysDoses.firstIndex(where: { $0.id == dose.id }) {
            todaysDoses[index] = dose
        }
        
        // Update in upcoming doses
        if let index = upcomingDoses.firstIndex(where: { $0.id == dose.id }) {
            upcomingDoses[index] = dose
        }
    }
    
    private func updateAdherenceReports() {
        for medication in medications {
            for period in AdherencePeriod.allCases {
                adherenceReports[medication.id] = getAdherenceReport(for: medication.id, period: period)
            }
        }
    }
    
    private func getAllDoses() -> [MedicationDose] {
        // In a real implementation, this would load from Core Data
        return todaysDoses + upcomingDoses
    }
    
    private func findDose(by id: UUID) -> MedicationDose? {
        return getAllDoses().first { $0.id == id }
    }
}

// MARK: - Core Data Operations

extension MedicationService {
    private func saveMedicationToCore(_ medication: Medication) async throws {
        guard let user = currentUser else {
            throw MedicationError.invalidMedicationData
        }
        
        let context = coreDataManager.backgroundContext
        
        try await context.perform {
            let entity = MedicationEntity(context: context)
            entity.id = medication.id
            entity.name = medication.name
            entity.dosage = medication.dosage
            entity.frequency = medication.frequency.rawValue
            entity.medicationType = medication.medicationType.rawValue
            entity.prescribedBy = medication.prescribedBy
            entity.startDate = medication.startDate
            entity.endDate = medication.endDate
            entity.instructions = medication.instructions
            entity.isActive = medication.isActive
            entity.reminderEnabled = medication.reminderEnabled
            entity.color = medication.color.rawValue
            entity.shape = medication.shape.rawValue
            entity.user = user
            
            // Encode arrays as JSON
            if let sideEffectsData = try? JSONEncoder().encode(medication.sideEffects) {
                entity.sideEffects = sideEffectsData
            }
            
            if let reminderTimesData = try? JSONEncoder().encode(medication.reminderTimes) {
                entity.reminderTimes = reminderTimesData
            }
            
            try context.save()
        }
    }
    
    private func saveDoseToCore(_ dose: MedicationDose) async throws {
        guard let user = currentUser else {
            throw MedicationError.invalidMedicationData
        }
        
        let context = coreDataManager.backgroundContext
        
        try await context.perform {
            let entity = MedicationDoseEntity(context: context)
            entity.id = dose.id
            entity.medicationId = dose.medicationId
            entity.scheduledTime = dose.scheduledTime
            entity.actualTime = dose.actualTime
            entity.status = dose.status.rawValue
            entity.notes = dose.notes
            entity.skippedReason = dose.skippedReason
            entity.user = user
            
            if let sideEffectsData = try? JSONEncoder().encode(dose.sideEffectsExperienced) {
                entity.sideEffectsExperienced = sideEffectsData
            }
            
            try context.save()
        }
    }
    
    private func loadMedicationsFromCore() async throws -> [Medication] {
        guard let user = currentUser else {
            throw MedicationError.invalidMedicationData
        }
        
        let context = coreDataManager.backgroundContext
        
        return try await context.perform {
            let request = NSFetchRequest<MedicationEntity>(entityName: "MedicationEntity")
            request.predicate = NSPredicate(format: "user == %@", user)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationEntity.name, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let frequency = MedicationFrequency(rawValue: entity.frequency),
                      let medicationType = MedicationType(rawValue: entity.medicationType),
                      let color = MedicationColor(rawValue: entity.color),
                      let shape = MedicationShape(rawValue: entity.shape) else {
                    return nil
                }
                
                var sideEffects: [String] = []
                if let sideEffectsData = entity.sideEffects,
                   let decodedSideEffects = try? JSONDecoder().decode([String].self, from: sideEffectsData) {
                    sideEffects = decodedSideEffects
                }
                
                var reminderTimes: [Date] = []
                if let reminderTimesData = entity.reminderTimes,
                   let decodedTimes = try? JSONDecoder().decode([Date].self, from: reminderTimesData) {
                    reminderTimes = decodedTimes
                }
                
                return Medication(
                    name: entity.name,
                    dosage: entity.dosage,
                    frequency: frequency,
                    medicationType: medicationType,
                    prescribedBy: entity.prescribedBy,
                    startDate: entity.startDate,
                    endDate: entity.endDate,
                    instructions: entity.instructions,
                    sideEffects: sideEffects,
                    isActive: entity.isActive,
                    reminderEnabled: entity.reminderEnabled,
                    reminderTimes: reminderTimes,
                    color: color,
                    shape: shape
                )
            }
        }
    }
    
    private func deleteMedicationFromCore(_ medicationId: UUID) async throws {
        guard let user = currentUser else {
            throw MedicationError.invalidMedicationData
        }
        
        let context = coreDataManager.backgroundContext
        
        try await context.perform {
            let request = NSFetchRequest<MedicationEntity>(entityName: "MedicationEntity")
            request.predicate = NSPredicate(format: "id == %@ AND user == %@", medicationId as CVarArg, user)
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            
            try context.save()
        }
    }
}

// MARK: - Error Types

enum MedicationError: LocalizedError {
    case saveFailed(String)
    case loadFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case notificationPermissionDenied
    case invalidMedicationData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save medication: \(message)"
        case .loadFailed(let message):
            return "Failed to load medications: \(message)"
        case .updateFailed(let message):
            return "Failed to update medication: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete medication: \(message)"
        case .notificationPermissionDenied:
            return "Notification permission is required for medication reminders"
        case .invalidMedicationData:
            return "Invalid medication data provided"
        }
    }
}