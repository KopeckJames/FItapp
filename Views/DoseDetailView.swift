import SwiftUI

struct DoseDetailView: View {
    let dose: MedicationDose
    let medication: Medication?
    @ObservedObject var medicationService: MedicationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var notes = ""
    @State private var selectedSideEffects: Set<String> = []
    @State private var customSideEffect = ""
    @State private var skipReason = ""
    @State private var showingSkipOptions = false
    @State private var isLoading = false
    
    private let skipReasons = [
        "Forgot to take",
        "Felt sick",
        "Ran out of medication",
        "Side effects",
        "Doctor's advice",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Medication info header
                        medicationInfoHeader
                        
                        // Dose status section
                        doseStatusSection
                        
                        // Action buttons
                        if dose.status == .pending {
                            actionButtons
                        }
                        
                        // Notes section
                        notesSection
                        
                        // Side effects section
                        if dose.status == .taken || dose.status == .pending {
                            sideEffectsSection
                        }
                        
                        // Skip reason section
                        if dose.status == .skipped || showingSkipOptions {
                            skipReasonSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Dose Details")
            .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Medication Info Header
    
    private var medicationInfoHeader: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(medication?.color.color ?? .gray)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: medication?.medicationType.icon ?? "pill.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication?.name ?? "Unknown Medication")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(medication?.dosage ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(medication?.medicationType.rawValue ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Dose Status Section
    
    private var doseStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dose Information")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                StatusBadge(status: dose.status)
            }
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "clock.fill",
                    title: "Scheduled Time",
                    value: dose.scheduledTime.formatted(date: .abbreviated, time: .shortened),
                    color: .blue
                )
                
                if let actualTime = dose.actualTime {
                    InfoRow(
                        icon: "checkmark.circle.fill",
                        title: "Actual Time",
                        value: actualTime.formatted(date: .abbreviated, time: .shortened),
                        color: .green
                    )
                    
                    let timeDifference = actualTime.timeIntervalSince(dose.scheduledTime)
                    let minutes = Int(abs(timeDifference) / 60)
                    
                    if minutes > 0 {
                        InfoRow(
                            icon: timeDifference > 0 ? "clock.arrow.circlepath" : "clock.badge.checkmark",
                            title: timeDifference > 0 ? "Taken Late" : "Taken Early",
                            value: "\(minutes) minutes",
                            color: timeDifference > 0 ? .orange : .blue
                        )
                    }
                }
                
                if dose.isOverdue && dose.status == .pending {
                    InfoRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Status",
                        value: "Overdue",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await markAsTaken()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Taken")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await snoozeReminder()
                    }
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Snooze 15m")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: {
                    showingSkipOptions = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Skip Dose")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.white)
            
            if dose.status == .pending {
                TextField("Add notes about this dose...", text: $notes, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(3...6)
            } else if let existingNotes = dose.notes, !existingNotes.isEmpty {
                Text(existingNotes)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            } else {
                Text("No notes added")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Side Effects Section
    
    private var sideEffectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Side Effects")
                .font(.headline)
                .foregroundColor(.white)
            
            if dose.status == .pending {
                VStack(alignment: .leading, spacing: 8) {
                    if let knownSideEffects = medication?.sideEffects, !knownSideEffects.isEmpty {
                        Text("Known side effects for this medication:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(knownSideEffects, id: \.self) { sideEffect in
                                Button(action: {
                                    if selectedSideEffects.contains(sideEffect) {
                                        selectedSideEffects.remove(sideEffect)
                                    } else {
                                        selectedSideEffects.insert(sideEffect)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: selectedSideEffects.contains(sideEffect) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedSideEffects.contains(sideEffect) ? .green : .gray)
                                        
                                        Text(sideEffect)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add custom side effect", text: $customSideEffect)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        Button("Add") {
                            if !customSideEffect.isEmpty {
                                selectedSideEffects.insert(customSideEffect)
                                customSideEffect = ""
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .disabled(customSideEffect.isEmpty)
                    }
                }
            } else if !dose.sideEffectsExperienced.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(dose.sideEffectsExperienced, id: \.self) { sideEffect in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text(sideEffect)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
            } else {
                Text("No side effects reported")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Skip Reason Section
    
    private var skipReasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skip Reason")
                .font(.headline)
                .foregroundColor(.white)
            
            if showingSkipOptions {
                VStack(spacing: 8) {
                    ForEach(skipReasons, id: \.self) { reason in
                        Button(action: {
                            skipReason = reason
                        }) {
                            HStack {
                                Image(systemName: skipReason == reason ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(skipReason == reason ? Color(red: 0.7, green: 0.9, blue: 0.3) : .gray)
                                
                                Text(reason)
                                    .font(.body)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if skipReason == "Other" {
                        TextField("Please specify...", text: $customSideEffect)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    Button(action: {
                        Task {
                            await markAsSkipped()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                Text("Confirm Skip")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(skipReason.isEmpty || isLoading)
                }
            } else if let existingReason = dose.skippedReason, !existingReason.isEmpty {
                Text(existingReason)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        notes = dose.notes ?? ""
        selectedSideEffects = Set(dose.sideEffectsExperienced)
        skipReason = dose.skippedReason ?? ""
    }
    
    private func markAsTaken() async {
        isLoading = true
        
        do {
            try await medicationService.markDoseTaken(
                dose,
                at: Date(),
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch {
            // Handle error
        }
        
        isLoading = false
    }
    
    private func markAsSkipped() async {
        isLoading = true
        
        do {
            let finalReason = skipReason == "Other" ? customSideEffect : skipReason
            try await medicationService.markDoseSkipped(dose, reason: finalReason)
            dismiss()
        } catch {
            // Handle error
        }
        
        isLoading = false
    }
    
    private func snoozeReminder() async {
        isLoading = true
        
        do {
            try await medicationService.snoozeReminder(dose)
            dismiss()
        } catch {
            // Handle error
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let status: DoseStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
            
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 25)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DoseDetailView(
        dose: MedicationDose(
            medicationId: UUID(),
            scheduledTime: Date(),
            status: .pending
        ),
        medication: nil,
        medicationService: MedicationService()
    )
    .preferredColorScheme(.dark)
}