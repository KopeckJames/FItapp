import SwiftUI
import UserNotifications

struct MedicationSettingsView: View {
    @ObservedObject var medicationService: MedicationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var badgeEnabled = true
    @State private var defaultSnoozeMinutes = 15
    @State private var reminderAdvanceMinutes = 0
    @State private var showMissedDoseReminders = true
    @State private var autoMarkOverdue = false
    @State private var autoMarkOverdueHours = 2
    @State private var exportFormat = "CSV"
    @State private var includeNotes = true
    @State private var includeSideEffects = true
    @State private var dateRange = "Last 30 Days"
    
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    @State private var showingNotificationSettings = false
    
    private let snoozeOptions = [5, 10, 15, 30, 60]
    private let reminderAdvanceOptions = [0, 5, 10, 15, 30]
    private let overdueOptions = [1, 2, 4, 6, 12, 24]
    private let exportFormats = ["CSV", "PDF", "JSON"]
    private let dateRangeOptions = ["Last 7 Days", "Last 30 Days", "Last 3 Months", "Last Year", "All Time"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Notification Settings
                        notificationSettingsSection
                        
                        // Reminder Settings
                        reminderSettingsSection
                        
                        // Adherence Settings
                        adherenceSettingsSection
                        
                        // Data Export Settings
                        dataExportSection
                        
                        // Advanced Settings
                        advancedSettingsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Medication Settings")
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
        .sheet(isPresented: $showingExportSheet) {
            DataExportView(
                medicationService: medicationService,
                format: exportFormat,
                includeNotes: includeNotes,
                includeSideEffects: includeSideEffects,
                dateRange: dateRange
            )
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all medication data. This action cannot be undone.")
        }
    }
    
    // MARK: - Notification Settings
    
    private var notificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Notifications", icon: "bell.fill")
            
            VStack(spacing: 12) {
                SettingsToggle(
                    title: "Enable Notifications",
                    subtitle: "Receive medication reminders",
                    isOn: $notificationsEnabled
                ) {
                    if notificationsEnabled {
                        requestNotificationPermission()
                    }
                }
                
                if notificationsEnabled {
                    SettingsToggle(
                        title: "Sound",
                        subtitle: "Play sound with notifications",
                        isOn: $soundEnabled
                    )
                    
                    SettingsToggle(
                        title: "Badge",
                        subtitle: "Show badge count on app icon",
                        isOn: $badgeEnabled
                    )
                    
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                                .frame(width: 25)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("System Notification Settings")
                                    .font(.body)
                                    .foregroundColor(.white)
                                
                                Text("Configure in iOS Settings")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Reminder Settings
    
    private var reminderSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Reminders", icon: "clock.fill")
            
            VStack(spacing: 12) {
                SettingsPicker(
                    title: "Default Snooze Duration",
                    subtitle: "How long to snooze reminders",
                    selection: $defaultSnoozeMinutes,
                    options: snoozeOptions,
                    formatter: { "\($0) minutes" }
                )
                
                SettingsPicker(
                    title: "Reminder Advance Time",
                    subtitle: "Show reminders before dose time",
                    selection: $reminderAdvanceMinutes,
                    options: reminderAdvanceOptions,
                    formatter: { $0 == 0 ? "On time" : "\($0) minutes early" }
                )
                
                SettingsToggle(
                    title: "Missed Dose Reminders",
                    subtitle: "Remind about missed doses",
                    isOn: $showMissedDoseReminders
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Adherence Settings
    
    private var adherenceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Adherence Tracking", icon: "chart.line.uptrend.xyaxis")
            
            VStack(spacing: 12) {
                SettingsToggle(
                    title: "Auto-mark Overdue Doses",
                    subtitle: "Automatically mark doses as missed after delay",
                    isOn: $autoMarkOverdue
                )
                
                if autoMarkOverdue {
                    SettingsPicker(
                        title: "Auto-mark Delay",
                        subtitle: "Hours after scheduled time",
                        selection: $autoMarkOverdueHours,
                        options: overdueOptions,
                        formatter: { "\($0) hours" }
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Data Export Section
    
    private var dataExportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Data Export", icon: "square.and.arrow.up")
            
            VStack(spacing: 12) {
                SettingsPicker(
                    title: "Export Format",
                    subtitle: "File format for exported data",
                    selection: $exportFormat,
                    options: exportFormats,
                    formatter: { $0 }
                )
                
                SettingsPicker(
                    title: "Date Range",
                    subtitle: "Time period to include",
                    selection: $dateRange,
                    options: dateRangeOptions,
                    formatter: { $0 }
                )
                
                SettingsToggle(
                    title: "Include Notes",
                    subtitle: "Export dose notes and comments",
                    isOn: $includeNotes
                )
                
                SettingsToggle(
                    title: "Include Side Effects",
                    subtitle: "Export reported side effects",
                    isOn: $includeSideEffects
                )
                
                Button(action: { showingExportSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                        
                        Text("Export Medication Data")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Advanced Settings
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Advanced", icon: "gear")
            
            VStack(spacing: 12) {
                Button(action: { 
                    Task {
                        await syncWithHealthKit()
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync with HealthKit")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text("Import/export to Apple Health")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: clearCache) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.orange)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Cache")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text("Free up storage space")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingResetAlert = true }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset All Data")
                                .font(.body)
                                .foregroundColor(.red)
                            
                            Text("Permanently delete all medication data")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    notificationsEnabled = granted
                }
            } catch {
                await MainActor.run {
                    notificationsEnabled = false
                }
            }
        }
    }
    
    private func syncWithHealthKit() async {
        // Implement HealthKit sync
    }
    
    private func clearCache() {
        // Implement cache clearing
    }
    
    private func resetAllData() {
        // Implement data reset
    }
}

// MARK: - Supporting Views

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let action: (() -> Void)?
    
    init(title: String, subtitle: String, isOn: Binding<Bool>, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.action = action
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    action?()
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SettingsPicker<T: Hashable>: View {
    let title: String
    let subtitle: String
    @Binding var selection: T
    let options: [T]
    let formatter: (T) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(formatter(option)).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Data Export View

struct DataExportView: View {
    @ObservedObject var medicationService: MedicationService
    let format: String
    let includeNotes: Bool
    let includeSideEffects: Bool
    let dateRange: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportComplete = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if isExporting {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.3)))
                                .scaleEffect(2)
                            
                            Text("Exporting your medication data...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    } else if exportComplete {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Export Complete!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Your medication data has been exported successfully.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                            
                            Text("Export Medication Data")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ExportDetailRow(title: "Format", value: format)
                                ExportDetailRow(title: "Date Range", value: dateRange)
                                ExportDetailRow(title: "Include Notes", value: includeNotes ? "Yes" : "No")
                                ExportDetailRow(title: "Include Side Effects", value: includeSideEffects ? "Yes" : "No")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(12)
                            
                            Button(action: startExport) {
                                Text("Start Export")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(exportComplete ? "Done" : "Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
            }
        }
    }
    
    private func startExport() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            exportComplete = true
        }
    }
}

struct ExportDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    MedicationSettingsView(medicationService: MedicationService())
        .preferredColorScheme(.dark)
}