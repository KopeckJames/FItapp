import SwiftUI

struct MedicationDetailView: View {
    let medication: Medication
    @ObservedObject var medicationService: MedicationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var selectedPeriod = AdherencePeriod.month
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Medication header
                        medicationHeader
                        
                        // Quick actions
                        quickActions
                        
                        // Adherence summary
                        adherenceSummary
                        
                        // Recent doses
                        recentDoses
                        
                        // Medication details
                        medicationDetails
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Medication Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditView = true }) {
                            Label("Edit Medication", systemImage: "pencil")
                        }
                        
                        Button(action: toggleActiveStatus) {
                            Label(medication.isActive ? "Deactivate" : "Activate", 
                                  systemImage: medication.isActive ? "pause.circle" : "play.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete Medication", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditMedicationView(medication: medication, medicationService: medicationService)
        }
        .alert("Delete Medication", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await medicationService.deleteMedication(medication)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(medication.name)? This action cannot be undone.")
        }
    }
    
    // MARK: - Medication Header
    
    private var medicationHeader: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(medication.color.color)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: medication.medicationType.icon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(medication.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(medication.dosage)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Label(medication.medicationType.rawValue, systemImage: medication.medicationType.icon)
                            .font(.caption)
                            .foregroundColor(medication.medicationType.color)
                        
                        Label(medication.frequency.rawValue, systemImage: medication.frequency.icon)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if !medication.isActive {
                        Label("Inactive", systemImage: "pause.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            
            // Next dose info
            if let nextDose = medication.nextDoseTime, medication.isActive {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Dose")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(nextDose, style: .time)
                            .font(.headline)
                            .foregroundColor(medication.isOverdue ? .red : Color(red: 0.7, green: 0.9, blue: 0.3))
                    }
                    
                    Spacer()
                    
                    if medication.isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        let timeUntilNext = nextDose.timeIntervalSinceNow
                        let hours = Int(timeUntilNext / 3600)
                        let minutes = Int((timeUntilNext.truncatingRemainder(dividingBy: 3600)) / 60)
                        
                        if hours > 0 {
                            Text("in \(hours)h \(minutes)m")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else if minutes > 0 {
                            Text("in \(minutes)m")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Now")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "pills.fill",
                    title: "Take Now",
                    color: .green
                ) {
                    // Handle take now action
                }
                
                QuickActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "Snooze",
                    color: .orange
                ) {
                    // Handle snooze action
                }
                
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "View Report",
                    color: .blue
                ) {
                    // Handle view report action
                }
                
                QuickActionButton(
                    icon: "bell.fill",
                    title: medication.reminderEnabled ? "Disable" : "Enable",
                    color: medication.reminderEnabled ? .red : Color(red: 0.7, green: 0.9, blue: 0.3)
                ) {
                    toggleReminders()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Adherence Summary
    
    private var adherenceSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Adherence Summary")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AdherencePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
            }
            
            let report = medicationService.getAdherenceReport(for: medication.id, period: selectedPeriod)
            
            HStack(spacing: 20) {
                // Adherence percentage
                VStack(spacing: 8) {
                    Text("\(Int(report.adherencePercentage))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(adherenceColor(report.adherencePercentage))
                    
                    Text("Adherence")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Stats grid
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        StatItem(
                            icon: "checkmark.circle.fill",
                            value: "\(report.takenDoses)",
                            label: "Taken",
                            color: .green
                        )
                        
                        StatItem(
                            icon: "xmark.circle.fill",
                            value: "\(report.skippedDoses)",
                            label: "Missed",
                            color: .red
                        )
                    }
                    
                    HStack(spacing: 20) {
                        StatItem(
                            icon: "flame.fill",
                            value: "\(report.streak)",
                            label: "Streak",
                            color: .orange
                        )
                        
                        StatItem(
                            icon: "star.fill",
                            value: "\(report.longestStreak)",
                            label: "Best",
                            color: .yellow
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Doses
    
    private var recentDoses: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Doses")
                .font(.headline)
                .foregroundColor(.white)
            
            // Placeholder for recent doses - would be populated from medication service
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        
                        Text("Today, 8:00 AM")
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Taken")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Medication Details
    
    private var medicationDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medication Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let prescribedBy = medication.prescribedBy {
                    DetailRow(title: "Prescribed By", value: prescribedBy, icon: "person.fill")
                }
                
                DetailRow(
                    title: "Start Date",
                    value: medication.startDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar"
                )
                
                if let endDate = medication.endDate {
                    DetailRow(
                        title: "End Date",
                        value: endDate.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar.badge.minus"
                    )
                }
                
                if let instructions = medication.instructions {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                                .frame(width: 20)
                            
                            Text("Instructions")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        Text(instructions)
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                if !medication.sideEffects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            
                            Text("Known Side Effects")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(medication.sideEffects, id: \.self) { sideEffect in
                                Text(sideEffect)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                if medication.reminderEnabled && !medication.reminderTimes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                                .frame(width: 20)
                            
                            Text("Reminder Times")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(medication.reminderTimes.sorted(by: <), id: \.self) { time in
                                Text(time, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.7, green: 0.9, blue: 0.3).opacity(0.3))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func toggleActiveStatus() {
        Task {
            var updatedMedication = medication
            // Create new medication with toggled active status
            // This would need proper implementation based on your Medication struct
            try? await medicationService.updateMedication(updatedMedication)
        }
    }
    
    private func toggleReminders() {
        Task {
            var updatedMedication = medication
            // Create new medication with toggled reminder status
            // This would need proper implementation based on your Medication struct
            try? await medicationService.updateMedication(updatedMedication)
        }
    }
    
    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 30..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Edit Medication View (Placeholder)

struct EditMedicationView: View {
    let medication: Medication
    @ObservedObject var medicationService: MedicationService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Text("Edit Medication")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Edit functionality would be implemented here")
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.3))
                }
            }
        }
    }
}

#Preview {
    MedicationDetailView(
        medication: Medication(
            name: "Metformin",
            dosage: "500mg",
            frequency: .twiceDaily,
            medicationType: .metformin
        ),
        medicationService: MedicationService()
    )
    .preferredColorScheme(.dark)
}