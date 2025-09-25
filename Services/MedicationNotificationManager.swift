import Foundation
import UserNotifications
import Combine

class MedicationNotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let doseActionSubject = PassthroughSubject<DoseNotificationAction, Never>()
    
    var doseActionPublisher: AnyPublisher<DoseNotificationAction, Never> {
        doseActionSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await MainActor.run {
                isAuthorized = granted
                authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                await registerNotificationCategories()
            }
        } catch {
            throw MedicationError.notificationPermissionDenied
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
                isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerNotificationCategories() async {
        let takenAction = UNNotificationAction(
            identifier: "DOSE_TAKEN",
            title: "Mark as Taken",
            options: [.foreground]
        )
        
        let skipAction = UNNotificationAction(
            identifier: "DOSE_SKIP",
            title: "Skip Dose",
            options: [.destructive]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "DOSE_SNOOZE",
            title: "Snooze 15 min",
            options: []
        )
        
        let medicationCategory = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([medicationCategory])
    }
    
    // MARK: - Scheduling Reminders
    
    func scheduleReminders(for medication: Medication) async throws {
        guard isAuthorized else {
            try await requestAuthorization()
        }
        
        // Cancel existing reminders for this medication
        await cancelReminders(for: medication.id)
        
        let calendar = Calendar.current
        let now = Date()
        let endDate = medication.endDate ?? calendar.date(byAdding: .year, value: 1, to: now) ?? now
        
        // Schedule reminders for the next 30 days or until end date
        let scheduleEndDate = min(endDate, calendar.date(byAdding: .day, value: 30, to: now) ?? now)
        
        var currentDate = max(medication.startDate, now)
        
        while currentDate <= scheduleEndDate {
            for reminderTime in medication.reminderTimes {
                if let scheduledTime = calendar.dateBySettingTimeOf(reminderTime, to: currentDate),
                   scheduledTime > now {
                    
                    let dose = MedicationDose(
                        medicationId: medication.id,
                        scheduledTime: scheduledTime
                    )
                    
                    try await scheduleNotification(for: medication, dose: dose)
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? scheduleEndDate
        }
    }
    
    private func scheduleNotification(for medication: Medication, dose: MedicationDose) async throws {
        let content = UNMutableNotificationContent()
        content.title = "💊 Medication Reminder"
        content.body = "Time to take your \(medication.name) (\(medication.dosage))"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.badge = 1
        
        // Add medication info to user info
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "doseId": dose.id.uuidString,
            "medicationName": medication.name,
            "dosage": medication.dosage,
            "scheduledTime": dose.scheduledTime.timeIntervalSince1970
        ]
        
        // Create trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dose.scheduledTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let identifier = "medication_\(medication.id.uuidString)_\(dose.scheduledTime.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try await notificationCenter.add(request)
    }
    
    func scheduleSnoozeReminder(for dose: MedicationDose, at snoozeTime: Date) async throws {
        guard let medication = await getMedication(for: dose.medicationId) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💊 Medication Reminder (Snoozed)"
        content.body = "Don't forget to take your \(medication.name) (\(medication.dosage))"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.badge = 1
        
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "doseId": dose.id.uuidString,
            "medicationName": medication.name,
            "dosage": medication.dosage,
            "scheduledTime": dose.scheduledTime.timeIntervalSince1970,
            "isSnooze": true
        ]
        
        let timeInterval = snoozeTime.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 1), repeats: false)
        
        let identifier = "snooze_\(dose.id.uuidString)_\(snoozeTime.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Canceling Reminders
    
    func cancelReminders(for medicationId: UUID) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let identifiersToCancel = pendingRequests
            .filter { $0.identifier.contains(medicationId.uuidString) }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
    }
    
    func cancelDoseNotification(_ doseId: UUID) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let identifiersToCancel = pendingRequests
            .filter { $0.identifier.contains(doseId.uuidString) }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
    }
    
    func cancelAllMedicationReminders() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let medicationIdentifiers = pendingRequests
            .filter { $0.identifier.hasPrefix("medication_") || $0.identifier.hasPrefix("snooze_") }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: medicationIdentifiers)
    }
    
    // MARK: - Helper Methods
    
    private func getMedication(for medicationId: UUID) async -> Medication? {
        // Get medication from Core Data directly
        guard let user = CoreDataManager.shared.getCurrentUser() else { return nil }
        
        let context = CoreDataManager.shared.context
        let request = NSFetchRequest<MedicationEntity>(entityName: "MedicationEntity")
        request.predicate = NSPredicate(format: "id == %@ AND user == %@", medicationId as CVarArg, user)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first,
                  let frequency = MedicationFrequency(rawValue: entity.frequency),
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
        } catch {
            print("Failed to fetch medication: \(error)")
            return nil
        }
    }
    
    func getPendingReminders() async -> [UNNotificationRequest] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.filter { $0.identifier.hasPrefix("medication_") }
    }
    
    func getDeliveredReminders() async -> [UNNotification] {
        let notifications = await notificationCenter.deliveredNotifications()
        return notifications.filter { $0.request.identifier.hasPrefix("medication_") }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension MedicationNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let doseIdString = userInfo["doseId"] as? String,
              let doseId = UUID(uuidString: doseIdString),
              let medicationIdString = userInfo["medicationId"] as? String,
              let medicationId = UUID(uuidString: medicationIdString) else {
            completionHandler()
            return
        }
        
        let actionType: DoseNotificationActionType
        
        switch response.actionIdentifier {
        case "DOSE_TAKEN":
            actionType = .taken
        case "DOSE_SKIP":
            actionType = .skipped
        case "DOSE_SNOOZE":
            actionType = .snooze
        default:
            completionHandler()
            return
        }
        
        let action = DoseNotificationAction(
            doseId: doseId,
            medicationId: medicationId,
            type: actionType
        )
        
        doseActionSubject.send(action)
        completionHandler()
    }
}

// MARK: - Notification Action Models

struct DoseNotificationAction {
    let doseId: UUID
    let medicationId: UUID
    let type: DoseNotificationActionType
}

enum DoseNotificationActionType {
    case taken
    case skipped
    case snooze
}

// MARK: - Calendar Extensions

extension Calendar {
    func dateBySettingTimeOf(_ time: Date, to date: Date) -> Date? {
        let timeComponents = dateComponents([.hour, .minute, .second], from: time)
        return self.date(bySettingHour: timeComponents.hour ?? 0,
                        minute: timeComponents.minute ?? 0,
                        second: timeComponents.second ?? 0,
                        of: date)
    }
}