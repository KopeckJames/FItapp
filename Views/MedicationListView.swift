import SwiftUI

struct MedicationListView: View {
    @ObservedObject var medicationService: MedicationService
    @State private var showingAddMedication = false
    @State private var selectedMedication: Medication?
    @State private var searchText = ""
    @State private var filterType: MedicationType?
    @State private var showActiveOnly = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search and filter bar
                searchAndFilterBar
                
                // Medications list
                if filteredMedications.isEmpty {
                    emptyStateView
                } else {
                    medicationsList
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView(medicationService: medicationService)
        }
        .sheet(item: $selectedMedication) { medication in
            MedicationDetailView(
                medication: medication,
                medicationService: medicationService
            )
        }
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search medications...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)
            
            // Filter options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Active/All toggle
                    Button(action: { showActiveOnly.toggle() }) {
                        Text(showActiveOnly ? "Active Only" : "All")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(showActiveOnly ? Color(red: 0.7, green: 0.9, blue: 0.3) : Color.gray.opacity(0.3))
                            .foregroundColor(showActiveOnly ? .white : .gray)
                            .cornerRadius(15)
                    }
                    
                    // Type filters
                    ForEach(MedicationType.allCases, id: \.self) { type in
                        Button(action: { 
                            filterType = filterType == type ? nil : type 
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.caption)
                                Text(type.rawValue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(filterType == type ? type.color : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Medications List
    
    private var medicationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredMedications) { medication in
                    MedicationRowView(
                        medication: medication,
                        medicationService: medicationService
                    ) {
                        selectedMedication = medication
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "pills.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Medications Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(searchText.isEmpty ? "Add your first medication to get started" : "Try adjusting your search or filters")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddMedication = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Medication")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var filteredMedications: [Medication] {
        var medications = medicationService.medications
        
        // Filter by active status
        if showActiveOnly {
            medications = medications.filter { $0.isActive }
        }
        
        // Filter by type
        if let filterType = filterType {
            medications = medications.filter { $0.medicationType == filterType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            medications = medications.filter { medication in
                medication.name.localizedCaseInsensitiveContains(searchText) ||
                medication.dosage.localizedCaseInsensitiveContains(searchText) ||
                medication.medicationType.rawValue.localizedCaseInsensitiveContains(searchText) ||
                (medication.prescribedBy?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return medications.sorted { $0.name < $1.name }
    }
}

// MARK: - Medication Row View

struct MedicationRowView: View {
    let medication: Medication
    @ObservedObject var medicationService: MedicationService
    let onTap: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Medication icon
                ZStack {
                    Circle()
                        .fill(medication.color.color)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: medication.medicationType.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                // Medication info
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Image(systemName: medication.frequency.icon)
                            .font(.caption)
                            .foregroundColor(medication.medicationType.color)
                        
                        Text(medication.frequency.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if !medication.isActive {
                            Text("• Inactive")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                // Next dose info
                VStack(alignment: .trailing, spacing: 4) {
                    if let nextDose = medication.nextDoseTime {
                        Text("Next dose")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(nextDose, style: .time)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(medication.isOverdue ? .red : Color(red: 0.7, green: 0.9, blue: 0.3))
                    } else {
                        Text("No reminders")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Adherence indicator
                    if let adherenceReport = medicationService.adherenceReports[medication.id] {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(adherenceColor(adherenceReport.adherencePercentage))
                                .frame(width: 8, height: 8)
                            
                            Text("\(Int(adherenceReport.adherencePercentage))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // More options button
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(90))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Medication Options", isPresented: $showingActionSheet) {
            Button("Edit Medication") {
                // Handle edit
            }
            
            Button("View Adherence Report") {
                // Handle adherence report
            }
            
            Button(medication.isActive ? "Deactivate" : "Activate") {
                Task {
                    var updatedMedication = medication
                    updatedMedication = Medication(
                        name: medication.name,
                        dosage: medication.dosage,
                        frequency: medication.frequency,
                        medicationType: medication.medicationType,
                        prescribedBy: medication.prescribedBy,
                        startDate: medication.startDate,
                        endDate: medication.endDate,
                        instructions: medication.instructions,
                        sideEffects: medication.sideEffects,
                        isActive: !medication.isActive,
                        reminderEnabled: medication.reminderEnabled,
                        reminderTimes: medication.reminderTimes,
                        color: medication.color,
                        shape: medication.shape
                    )
                    
                    try? await medicationService.updateMedication(updatedMedication)
                }
            }
            
            Button("Delete", role: .destructive) {
                Task {
                    try? await medicationService.deleteMedication(medication)
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func adherenceColor(_ percentage: Double) -> Color {
        switch percentage {
        case 80...100:
            return .green
        case 60..<80:
            return .yellow
        case 30..<60:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    MedicationListView(medicationService: MedicationService())
        .preferredColorScheme(.dark)
}